---
title: Streams
toc: true
weight: 4
---

A WebTransport stream functions similarly to a [QUIC Stream]({{< relref "../quic/streams.md" >}}). In particular, the stream state machines are exactly the same, as detailed in the [QUIC Stream documentation]({{< relref "../quic/streams.md#states" >}}). WebTransport supports both unidirectional and bidirectional streams.

The main difference between a QUIC stream and a WebTransport stream lies in the type of error codes used to reset the stream: QUIC allows error codes up to a 62-bit unsigned integer, while WebTransport error codes are limited to a 32-bit unsigned integer.


## Stream Errors

When a stream is reset (i.e. when `CancelRead` or `CancelWrite` are used), applications can communicate an error code to the peer. Subsequent calls to Read and Write may return an error that can be type-asserted as a `quic.StreamError`.

WebTransport itself does not interpret this value; instead, it is the responsibility of the application layer to assign specific meanings to different error codes. 

Below is an example of how to type-assert an error as a `webtransport.StreamError`:

```go
var streamErr *webtransport.StreamError
if errors.As(err, &streamErr) {
  errorCode := streamErr.ErrorCode
}
```
