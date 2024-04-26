---
title: Running a Client
toc: true
weight: 2
---

To dial a WebTransport session, initialize a `webtransport.Dialer`, and call the `Dial` function.

```go
var d webtransport.Dialer
// optionally, add custom headers
var headers http.Header
headers.Add("foo", "bar")
rsp, sess, err := d.Dial(ctx, "https://example.com/webtransport", headers)
// err is only nil if rsp.StatusCode is a 2xx
// Handle the session. Here goes the application logic.
```

This initiates a new WebTransport session with the server by sending an Extended CONNECT request to the server.
The server might reject this request, in which case the status code of the HTTP response will not be in the 2xx range.

The parameters for the underlying QUIC connection can be adjusted by setting the `QUICConfig` on the `Dialer`. [Datagram support]({{< relref "../quic/datagrams.md" >}}) is required by WebTransport, and must be enabled on using `quic.Config.EnableDatagrams`.

## 📝 Future Work

* Using the same QUIC connection for WebTransport and HTTP/3: [#147](https://github.com/quic-go/webtransport-go/issues/147)
* Allow Optimistic Opening of Streams: [#136](https://github.com/quic-go/webtransport-go/issues/136)
* Subprotocol Negotiation: [#132](https://github.com/quic-go/webtransport-go/issues/132)
