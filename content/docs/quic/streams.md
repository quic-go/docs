---
title: Using QUIC Streams
toc: true
weight: 6
---

QUIC is a stream-multiplexed transport. A `quic.Connection` fundamentally differs from the `net.Conn` and the `net.PacketConn` interface defined in the standard library.

Data is sent and received on (unidirectional and bidirectional) streams, not on the connection itself. The stream state machine is described in detail in [Section 3 of RFC 9000](https://datatracker.ietf.org/doc/html/rfc9000#section-3).

In addition to QUIC streams, application data can also sent in so-called QUIC datagram frames (see [datagrams]({{< relref path="datagrams.md" >}})), if implementations can negotiate support for it.


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

`OpenStream` attempts to open a new bidirectional stream  (`quic.Stream`), and it never blocks. If it's currently not possible to open a new stream, it returns a `net.Error` timeout error:

```go
str, err := conn.OpenStream()
if nerr, ok := err.(net.Error); ok && nerr.Timeout() {
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


## Reading, Writing, Closing and Resetting

Using QUIC streams is pretty straightforward. The `quic.ReceiveStream` implements the `io.Reader` interface, and the `quic.SendStream` implements the `io.Writer` interface. A bidirectional stream (`quic.Stream`) implements both these interfaces. Conceptually, a bidirectional stream can be thought of as the composition of two unidirectional streams in opposite directions.

Calling `Close` on a `quic.SendStream` or a `quic.Stream` closes the send side of the stream. On the receiver side, this will be surfaced as an `io.EOF` returned from the `io.Reader` once all data has been consumed. Note that for bidirectional streams, `Close` _only_ closes the send side of the stream. It is still possible to read from the stream until the peer closes or resets the stream.

In case the application wishes to abort sending on a `quic.SendStream` or a `quic.Stream` , it can reset the send side by calling `CancelWrite` with an application-defined error code (an unsigned 62-bit number). On the receiver side, this surfaced as a `quic.StreamError` containing that error code on the `io.Reader`. Note that for bidirectional streams, `CancelWrite` _only_ resets the send side of the stream. It is still possible to read from the stream until the peer closes or resets the stream.

Conversely, in case the application wishes to abort receiving from a `quic.ReceiveStream` or a `quic.Stream`, it can ask the sender to abort data transmission by calling `CancelRead` with an application-defined error code (an unsigned 62-bit number). On the receiver side, this surfaced as a `quic.StreamError` containing that error code on the `io.Writer`. Note that for bidirectional streams, `CancelWrite` _only_ resets the receive side of the stream. It is still possible to write to the stream.

A bidirectional stream is only closed once both the read and the write side of the stream have been either closed or reset. Only then the peer is granted a new stream according to the maximum number of concurrent streams configured via `quic.Config.MaxIncomingStreams`.


## 📝 Future Work

* Stream Priorities: [#437](https://github.com/quic-go/quic-go/issues/437)
* QUIC [Reliable Stream Reset](https://datatracker.ietf.org/doc/draft-ietf-quic-reliable-stream-reset/) extension: [#4139](https://github.com/quic-go/quic-go/issues/4139)
