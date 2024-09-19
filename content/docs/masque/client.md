---
title: Running a Client
toc: true
weight: 2
---

## Setting up a Proxied Connection

A client needs to be configured with the same URI template as the proxy. For more information on URI templates, see [URI Templates]({{< relref "proxy#uri-templates" >}}).

```go
t := uritemplate.MustNew("https://example.org:4443/masque?h={target_host}&p={target_port}")
cl := masque.Client{
  Template: t,
}
```

`Client.DialAddr` can then be used establish proxied connections to servers by hostname.
In this case, DNS resolution is handled by the proxy:
```go
// dial a target with a hostname
conn, rsp, err := cl.DialAddr(ctx, "quic-go.net:443")
```

`Client.Dial` can be used to establish proxied connections to servers by IP address:
```go
conn, rsp, err := cl.Dial(ctx, <*net.UDPAddr>)
```

The `net.PacketConn` returned from these methods is only non-nil if the proxy accepted the proxying request.
This is the case if the HTTP status code is in the 2xx range:
```go
conn, rsp, err := cl.DialAddr(ctx, "quic-go.net:443")
// ... handle error ...
if rsp.StatusCode < 200 && rsp.StatusCode > 299 {
  // proxying request rejected
  // The response status code and body might contain more information.
  return
}
// use conn to send and receive UDP datagrams to the target
```

Multiple UDP flows can be proxied over the same QUIC connection to the proxy by calling `DialAddr` and / or `Dial` multiple times on the same `Client`.

## 📝 Future Work

* Logging / Tracing: [#59](https://github.com/quic-go/masque-go/issues/59)
* Proxying IP packets over HTTP ([RFC 9484](https://datatracker.ietf.org/doc/html/rfc9484)): [#63](https://github.com/quic-go/masque-go/issues/63)
