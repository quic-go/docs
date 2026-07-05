---
title: Running a Client
toc: true
weight: 2
---

## Setting up a Proxied Connection

A client needs to be configured with the same URI template as the proxy. For more information on URI templates, see [URI Templates]({{< relref "proxy#uri-templates" >}}).

```go
template := uritemplate.MustNew("https://example.org:4443/masque?h={target_host}&p={target_port}")
```

Create a CONNECT-UDP request for the target, then use a `masque.Transport` to dial it.
The target is passed as `host:port`; when the host is a name, DNS resolution is handled by the proxy:
```go
req, err := masque.NewRequest(ctx, template, "quic-go.net:443")
// ... handle error ...

tr := masque.Transport{}
conn, rsp, err := tr.Dial(req)
```

For IP addresses, pass the address in the same `host:port` format:
```go
req, err := masque.NewRequest(ctx, template, "203.0.113.1:443")
// ... handle error ...

conn, rsp, err := tr.Dial(req)
```

It is possible to add HTTP headers to the CONNECT-UDP request before dialing:
```go
req, err := masque.NewRequest(ctx, template, "quic-go.net:443")
// ... handle error ...

req.Header().Set("Authorization", "Bearer token")
conn, rsp, err := tr.Dial(req)
```

The `*masque.Conn` returned from `Dial` is only non-nil if the proxy accepted the proxying request.
For a non-2xx response, `Dial` returns an error and the HTTP response:
```go
conn, rsp, err := tr.Dial(req)
if err != nil {
  if rsp != nil {
    // proxying request rejected
    // The response status code and body might contain more information.
  }
  return
}
// use conn to send and receive UDP datagrams to the target
```

Multiple UDP flows can be proxied over the same QUIC connection to the proxy by creating a `ClientConn` from an established QUIC connection:
```go
qconn, err := quic.DialAddr(ctx, "example.org:4443", tlsConf, &quic.Config{EnableDatagrams: true})
// ... handle error ...

cconn, err := tr.NewClientConn(qconn)
// ... handle error ...

req, err := masque.NewRequest(ctx, template, "quic-go.net:443")
// ... handle error ...

conn, rsp, err := cconn.Dial(req)
```

## 📝 Future Work

* Logging / Tracing: [#59](https://github.com/quic-go/masque-go/issues/59)
* Proxying a UDP Listener: [#64](https://github.com/quic-go/masque-go/issues/64)
