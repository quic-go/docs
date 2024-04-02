---
title: Running a Client
toc: true
weight: 2
---

To dial a WebTransport session, initialize a `webtransport.Dialer`, and call the `Dial` function.

```go
var d webtransport.Dialer
var headers http.Header
headers.Add("foo", "bar")
rsp, conn, err := d.Dial(ctx, "https://example.com/webtransport", headers)
// err is only nil if rsp.StatusCode is a 2xx
// Handle the connection. Here goes the application logic.
```

This initiates a new WebTransport session with the server. It is possible to pass additional HTTP header fields to the request.

When `Dial` is called

## 📝 Future Work

* Subprotocol Negotiation: [#132](https://github.com/quic-go/webtransport-go/issues/132)
