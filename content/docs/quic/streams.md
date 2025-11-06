---
title: QUIC Streams
toc: true
weight: 6
---

QUIC is a stream-multiplexed transport. A QUIC connection fundamentally differs from the `net.Conn` and the `net.PacketConn` interface defined in the standard library.

Application data is sent and received on (unidirectional and bidirectional) streams, not on the connection itself. The stream state machine is described in detail in [Section 3 of RFC 9000](https://datatracker.ietf.org/doc/html/rfc9000#section-3).

In addition to QUIC streams, application data can also be sent in so-called QUIC datagram frames (see [datagrams]({{< relref path="datagrams.md" >}})), if endpoints declare support for it.


## Stream Types

QUIC supports both unidirectional and bidirectional streams. A unidirectional stream is a stream that the initiator can only write to (`quic.SendStream`), and the receiver can only read from (`quic.ReceiveStream`). A bidirectional stream (`quic.Stream`) allows reading from and writing to for both sides.


## Accepting Streams

On the receiver side, bidirectional streams are accepted using `AcceptStream`. 

```go
for {
  str, err := conn.AcceptStream(context.Background())
  // ... error handling
  // handle the stream, usually in a new Go routine
}
```

`AcceptUniStream` accepts unidirectional streams:

```go
for {
  str, err := conn.AcceptUniStream(context.Background())
  // ... error handling
  // handle the stream, usually in a new Go routine
}
```

For most use cases, it makes sense to call these functions in a loop.
These functions return an error when the underlying QUIC connection is closed.


## Opening Streams

As described in [Flow Control for Streams]({{< relref "flowcontrol.md#stream-num" >}}), endpoints impose limits on how many streams a peer may open. The receiver may grant additional streams at any point in the connection (typically when existing streams are closed), but it means that at the time we want to open a new stream, we might not be able to do so.

`OpenStream` attempts to open a new bidirectional stream (`quic.Stream`), and it never blocks. If it's currently not possible to open a new stream, it returns a `quic.StreamLimitReachedError` error:

```go
str, err := conn.OpenStream()
if errors.Is(err, &quic.StreamLimitReachedError{}) {
  // It's currently not possible to open another stream,
  // but it might be possible later, once the peer allowed us to do so.
}
```

To open a new unidirectional (send) stream (`quic.SendStream`), use `OpenUniStream`.

`OpenStreamSync` opens a new bidirectional stream. If that's not possible due to the peer's stream limit, it blocks until the peer allows opening additional streams. In case that we're allowed to open a new stream, this methods returns right away:

```go
// wait up to 5s to open a new bidirectional stream
ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
defer cancel()
str, err := conn.OpenStreamSync(ctx)
```

`OpenUniStreamSync` is the version of this function to open a new unidirectional (send) stream.

Both `OpenStream` and `OpenStreamSync` return an error when the underlying QUIC connection is closed.


## Stream States {#states}

quic-go exposes three different stream abstractions: A `quic.SendStream` and a `quic.ReceiveStream`, for the two directions of unidirectional streams, and a `quic.Stream` for bidirectional streams.


### Send Stream

The `quic.SendStream` is a unidirectional stream opened by us. It implements the `io.Writer` interface. Invoking `Close` closes the stream, i.e. it sends a STREAM frame with the FIN bit set. On the receiver side, this will be surfaced as an `io.EOF` returned from the `io.Reader` once all data has been consumed. 

If the application needs to abruptly stop sending data on a stream, it can do so by by calling `CancelWrite` with an application-defined error code (an unsigned 62-bit number). This call immediately halts data transmission; any pending data will not be retransmitted. On the receiver side, this is surfaced as a `quic.StreamError` containing that error code on `stream.Read`.

Once `CancelWrite` has been called to abort the stream, subsequent calls to Close are ineffective (no-op) - the stream's abortive state cannot be reversed.

It is valid to call `CancelWrite` after `Close`. This immediately aborts transmission of stream data. Depending on the order in which the QUIC packets are received, the receiver will either surface this a normal or an abrupt stream termination to the application.


### Receive Stream

The `quic.ReceiveStream` is a unidirectional stream opened by the peer. It implements the `io.Reader` interface. It returns an `io.EOF` once the peer closes the stream, i.e. once we receive a STREAM frame with the FIN bit set.

In case the application is no longer interest in receiving data from a `quic.ReceiveStream`, it can ask the sender to abort data transmission by calling `CancelRead` with an application-defined error code (an unsigned 62-bit number). On the receiver side, this surfaced as a `quic.StreamError` containing that error code on the `io.Writer`. 


### Bidirectional Stream

Using QUIC streams is pretty straightforward. Conceptually, a bidirectional stream (`quic.Stream`) can be thought of as the composition of two unidirectional streams in opposite directions.

{{< callout type="warning" >}}
  Calling `Close` on a `quic.Stream` closes the send side of the stream. Note that for bidirectional streams, `Close` _only_ closes the send side of the stream. It is still possible to read from the stream until the peer closes or resets the stream.
{{< /callout >}}

`CancelWrite` **only** resets the send side of the stream. It is still possible to read from the stream until the peer closes or resets the stream. Similary, `CancelRead` **only** resets the receive side of the stream, and it is still possible to write to the stream.

A bidirectional stream is only closed once **both** the read and the write side of the stream have been either closed or reset. Only then the peer is granted a new stream according to the maximum number of concurrent streams configured via `quic.Config.MaxIncomingStreams`.


## Stream Errors

When a stream is reset (i.e. when `CancelRead` or `CancelWrite` are used), applications can communicate an error code (a 62-bit unsigned integer value) to the peer. Subsequent calls to Read and Write may return an error that can be type-asserted as a `quic.StreamError`.

QUIC itself does not interpret this value; instead, it is the responsibility of the application layer to assign specific meanings to different error codes. 

```go
var streamErr *quic.StreamError
if errors.As(err, &streamErr) {
  errorCode := streamErr.ErrorCode
}
```

In general, the error returned from `Read` and `Write` might not be a stream error at all: For example, the underlying QUIC connection might have been closed, which (implicitly) closes all streams as well. The error returned will then be one of the [QUIC connection errors]({{< relref "connection.md#error-assertion" >}}).


{{< callout type="warning" >}}
  Be aware of a potential race condition: if the read side is canceled by the receiver using one error code while the write side is simultaneously canceled by the sender with a different error code, the resulting error codes observed by each peer may not match.
{{< /callout >}}


## Stream Resets and Partial Reliability

When the sender cancels sending on a stream (either unidirectional or bidirectional), it immediately stops transmitting STREAM frames for that stream. This includes retransmissions: If any stream data for this stream is lost, it will not be retransmitted.

Conversely, the receiver does not need to wait for all data to be delivered before indicating to the application that the stream has been reset.


## 📝 Future Work

* Stream Priorities: [#437](https://github.com/quic-go/quic-go/issues/437)
