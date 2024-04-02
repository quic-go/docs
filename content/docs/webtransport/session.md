---
title: Session
toc: true
weight: 3
---

A WebTransport Session functions similarly to a [QUIC Connection]({{< relref "../quic/connection.md" >}}), enabling the opening and accepting of streams, as well as the sending and receiving of datagrams. 

The API of `webtransport.Session` is _almost_ identical to that of `quic.Connection`, with a few minor differences: For example, QUIC allows streams to be reset using a 62-bit error code, whereas WebTransport limits the error code range to 32 bits.

## Closing a WebTransport Session

The WebTransport session can be closed by calling the `CloseWithError` method:
```go
sess.CloseWithError(1234, "please stop talking to me 🤐")
```

Similar to closing a `quic.Connection`, this action causes all calls to `AcceptStream` and `OpenStream`, as well as stream `Read` and `Write` calls, to return immediately.

{{< callout type="warning" >}}
  `CloseWithError` only closes the WebTransport session, but not the underlying QUIC connection.
{{< /callout >}}

On the receiver side, this error will be surfaced as a `webtransport.SessionError`:
```go
var sessErr *webtransport.SessionError
if errors.As(err, &sessErr) {
  errorCode := sessErr.ErrorCode
  errorMessage := sessErr.Message
}
```

Additionally, the underlying QUIC connection might close for various reasons, potentially triggering any of the errors detailed in the [error assertion section]({{< relref "../quic/connection.md#error-assertion" >}}).


## 📝 Future Work

* WebTransport Datagrams: [#8](https://github.com/quic-go/webtransport-go/issues/8)
