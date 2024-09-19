---
title: Running a Proxy
toc: true
weight: 1
---

To create a MASQUE proxy server, the following steps are necessary:

1. Set up an HTTP/3 server that defines an `http.Handler` for the URI template.
2. Decode the client's request and create a socket to the target.
3. Use the `masque.Proxy` to handle proxying of the UDP packet flow.

## URI Templates

HTTP clients are configured to use a UDP proxy with a URI Template ([RFC 6570](https://datatracker.ietf.org/doc/html/rfc6570)).
This URI template encodes the target host and port number.

For example, for a proxy running on `https://proxy.example.com`, these are possible URI templates:
* `https://proxy.example.org:4443/masque?h={target_host}&p={target_port}`
* `https://proxy.example.org:4443/masque/{target_host}/{target_port}`

The `target_host` can either be a hostname or an IP address. In case a hostname is used, DNS resolution is handled by the proxy.

When receiving a request at the specified HTTP handler, the server decodes the URI template and opens a UDP socket to the requested target.

## Handling Proxying Requests

To run a CONNECT-UDP proxy on `https://example.org:4443` with the URI template `https://example.org:4443/masque?h={target_host}&p={target_port}`:

```go
t, err := uritemplate.New("https://example.org:4443/masque?h={target_host}&p={target_port}")
// ... error handling
var proxy masque.Proxy
http.Handle("/masque", func(w http.ResponseWriter, r *http.Request) {
  // parse the UDP proxying request
  mreq, err := masque.ParseRequest(r, t)
  if err != nil {
    var perr *masque.RequestParseError
    if errors.As(err, &perr) {
      w.WriteHeader(perr.HTTPStatus)
      return
    }
    w.WriteHeader(http.StatusBadRequest)
    return
  }

  // Optional: Whitelisting / blacklisting logic.
  err = proxy.Proxy(w, mreq)
  // ... error handling
}
```

The error returned from `masque ParseRequest` is a `masque.RequestParseError`, which contains a field 'HTTPStatus'. This allows the proxy to reject
invalid requests with the correct HTTP status code.

The `masque Request.Target` contains the requested target as `{target_host}:{target_port}`. Proxies can implement custom logic to decide which proxying requests are permissible.

{{< callout type="warning" >}}
  Applications may add custom header fields to the response header, but must not call `WriteHeader` on the `http.ResponseWriter`
  The header is sent when `Proxy.Proxy` is called.
{{< / callout >}}

## Controlling the Socket

`proxy.Proxy` creates a new connected UDP socket on `:0` to send UDP datagrams to the target.

An application that wishes a more fine-grained control over the socket can use `Proxy.ProxyConnectedSocket` instead of `Proxy.Proxy`:
```go
http.Handle("/masque", func(w http.ResponseWriter, r *http.Request) {
  // parse the UDP proxying request
  mreq, err := masque.ParseRequest(r, t)
  // ... handle error, as above ...

  // custom logic to resolve and create a UDP socket
  addr, err := net.ResolveUDPAddr("udp", mreq.Target)
  // ... handle error ...
  conn, err := net.DialUDP("udp", addr)
  // ... handle error ...

  err = proxy.ProxyConnectedSocket(w, mreq, conn)
  // ... handle error ...
}
```

## 📝 Future Work 

* Unconnected UDP sockets: [#3](https://github.com/quic-go/masque-go/issues/3)
* Use the Proxy-Status HTTP header ([RFC 9209](https://datatracker.ietf.org/doc/html/rfc9209)) to communicate failures: [#2](https://github.com/quic-go/masque-go/issues/2)
* Use GSO and GRO to speed up UDP packet processing: [#31](https://github.com/quic-go/masque-go/issues/31) and [#32](https://github.com/quic-go/masque-go/issues/32)
* Logging / Tracing: [#59](https://github.com/quic-go/masque-go/issues/59)
* Proxying IP packets over HTTP ([RFC 9484](https://datatracker.ietf.org/doc/html/rfc9484)): [#63](https://github.com/quic-go/masque-go/issues/63)
