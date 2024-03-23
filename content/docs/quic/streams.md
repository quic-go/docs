---
title: Using QUIC Streams
toc: true
weight: 4
---

## Accepting Streams

QUIC is a stream-multiplexed transport. A `quic.Connection` fundamentally differs from the `net.Conn` and the `net.PacketConn` interface defined in the standard library. Data is sent and received on (unidirectional and bidirectional) streams (and, if supported, in [datagrams]({{< relref path="datagrams.md" >}})), not on the connection itself. The stream state machine is described in detail in [Section 3 of RFC 9000](https://datatracker.ietf.org/doc/html/rfc9000#section-3).

Note: A unidirectional stream is a stream that the initiator can only write to (`quic.SendStream`), and the receiver can only read from (`quic.ReceiveStream`). A bidirectional stream (`quic.Stream`) allows reading from and writing to for both sides.

On the receiver side, streams are accepted using the `AcceptStream` (for bidirectional) and `AcceptUniStream` functions. For most user cases, it makes sense to call these functions in a loop:

```go
for {
  str, err := conn.AcceptStream(context.Background()) // for bidirectional streams
  // ... error handling
  // handle the stream, usually in a new Go routine
}
```

These functions return an error when the underlying QUIC connection is closed.

## Opening Streams

There are two slightly different ways to open streams, one synchronous and one (potentially) asynchronous. This API is necessary since the receiver grants us a certain number of streams that we're allowed to open. It may grant us additional streams later on (typically when existing streams are closed), but it means that at the time we want to open a new stream, we might not be able to do so.

Using the synchronous method `OpenStreamSync` for bidirectional streams, and `OpenUniStreamSync` for unidirectional streams, an application can block until the peer allows opening additional streams. In case that we're allowed to open a new stream, these methods return right away:

```go
ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
defer cancel()
str, err := conn.OpenStreamSync(ctx) // wait up to 5s to open a new bidirectional stream
```

The asynchronous version never blocks. If it's currently not possible to open a new stream, it returns a `net.Error` timeout error:

```go
str, err := conn.OpenStream()
if nerr, ok := err.(net.Error); ok && nerr.Timeout() {
  // It's currently not possible to open another stream,
  // but it might be possible later, once the peer allowed us to do so.
}
```

These functions return an error when the underlying QUIC connection is closed.

## Reading, Writing, Closing and Resetting

Using QUIC streams is pretty straightforward. The `quic.ReceiveStream` implements the `io.Reader` interface, and the `quic.SendStream` implements the `io.Writer` interface. A bidirectional stream (`quic.Stream`) implements both these interfaces. Conceptually, a bidirectional stream can be thought of as the composition of two unidirectional streams in opposite directions.

Calling `Close` on a `quic.SendStream` or a `quic.Stream` closes the send side of the stream. On the receiver side, this will be surfaced as an `io.EOF` returned from the `io.Reader` once all data has been consumed. Note that for bidirectional streams, `Close` _only_ closes the send side of the stream. It is still possible to read from the stream until the peer closes or resets the stream.

In case the application wishes to abort sending on a `quic.SendStream` or a `quic.Stream` , it can reset the send side by calling `CancelWrite` with an application-defined error code (an unsigned 62-bit number). On the receiver side, this surfaced as a `quic.StreamError` containing that error code on the `io.Reader`. Note that for bidirectional streams, `CancelWrite` _only_ resets the send side of the stream. It is still possible to read from the stream until the peer closes or resets the stream.

Conversely, in case the application wishes to abort receiving from a `quic.ReceiveStream` or a `quic.Stream`, it can ask the sender to abort data transmission by calling `CancelRead` with an application-defined error code (an unsigned 62-bit number). On the receiver side, this surfaced as a `quic.StreamError` containing that error code on the `io.Writer`. Note that for bidirectional streams, `CancelWrite` _only_ resets the receive side of the stream. It is still possible to write to the stream.

A bidirectional stream is only closed once both the read and the write side of the stream have been either closed or reset. Only then the peer is granted a new stream according to the maximum number of concurrent streams configured via `quic.Config.MaxIncomingStreams`.

## 📝 Future Work

* Stream Priorities: [#437](https://github.com/quic-go/quic-go/issues/437)
* QUIC [Reliable Stream Reset](https://datatracker.ietf.org/doc/draft-ietf-quic-reliable-stream-reset/) extension: [#4139](https://github.com/quic-go/quic-go/issues/4139)
