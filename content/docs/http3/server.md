---
title: Serving HTTP/3
toc: true
weight: 1
---

## Using `ListenAndServeQUIC`

The easiest way to start an HTTP/3 server is using
```go
mux := http.NewServeMux()
// ... add HTTP handlers to mux ...
// If mux is nil, the http.DefaultServeMux is used.
http3.ListenAndServeQUIC("0.0.0.0:443", "/path/to/cert", "/path/to/key", mux)
```

## Setting up a `http3.Server`

For more configurability, set up an `http3.Server` explicitly:
```go
server := http3.Server{
	Handler:    mux,
	Addr:       "0.0.0.0:443",
	TLSConfig:  http3.ConfigureTLSConfig(&tls.Config{}), // use your tls.Config here
	QuicConfig: &quic.Config{},
}
err := server.ListenAndServe()
```

`http3.ConfigureTLSConfig` takes a `tls.Config` and configures the `GetConfigForClient` such that the correct ALPN value for HTTP/3 is used.

## Using a `quic.Transport`

It is also possible to manually set up a `quic.Transport`, and then pass the listener to the server. This is useful when you want to set configuration options on the `quic.Transport`.
```go
tr := quic.Transport{Conn: conn}
tlsConf := http3.ConfigureTLSConfig(&tls.Config{})  // use your tls.Config here
quicConf := &quic.Config{} // QUIC connection options
server := http3.Server{}
ln, _ := tr.ListenEarly(tlsConf, quicConf)
err := server.ServeListener(ln)
```

### Demultiplexing non-HTTP Protocols

Alternatively, it is also possible to pass fully established QUIC connections to the HTTP/3 server. This is useful if the QUIC serves both HTTP/3 and other protocols. Connection can then be demultiplexed using the ALPN value (via `NextProtos` in the `tls.Config`).
```go
tr := quic.Transport{Conn: conn}
tlsConf := http3.ConfigureTLSConfig(&tls.Config{})  // use your tls.Config here
quicConf := &quic.Config{} // QUIC connection options
server := http3.Server{}
ln, _ := tr.ListenEarly(tlsConf, quicConf)
for {
	c, _ := ln.Accept()
	switch c.ConnectionState().TLS.NegotiatedProtocol {
	case http3.NextProtoH3:
		go server.ServeQUICConn(c) 
	// ... handle other protocols ...  
	}
}
```

## Advertising HTTP/3 via Alt-Svc

An HTTP/1.1 or HTTP/2 server can advertise that it is also offering the same resources on HTTP/3 using [HTTP Alternative Services](https://datatracker.ietf.org/doc/html/rfc7838#section-3) (Alt-Svc) header field. [Section 3.1.1 of RFC 9114](https://datatracker.ietf.org/doc/html/rfc9114#section-3.1.1) specifies how to use this field to advertise support for HTTP/3.

This allows HTTP clients to discover support for HTTP/3. Clients may still continue using the existing HTTP connection on top of TCP, but might decide to connect via QUIC the next time.

An `http.Handler` can be wrapped to automatically add the Alt-Svc header field for non-HTTP/3 requests:
```go
server := http3.Server{}
var handler http.Handler = http.NewServeMux()
// ... add HTTP handlers ...
handler = http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
	if r.ProtoMajor < 3 {
		err := server.SetQuicHeaders(w.Header())
		// ... handle error ...
	}
	handler.ServeHTTP(w, r)
})
```

### Reverse-Proxying

If the HTTP/3 server is located behind an L4 reverse proxy, it might be listening on a different UDP port than the port that is exposed to the internet. To accomodate for this common scenario, the external port can be configured using the `Port` field of the `http3.Server`:
```go
server := http3.Server{
	Port: 443, // SetQuicHeaders will now generate the Alt-Svc header for port 443
}
```

More complex scenarios can be handled by manually setting the Alt-Svc header field, or by overwriting the value added by `SetQuicHeaders`.

## 📝 Future Work

* Graceful shutdown: [#153](https://github.com/quic-go/quic-go/issues/153)
* Correctly deal with 0-RTT and HTTP/3 extensions: [#3855](https://github.com/quic-go/quic-go/issues/3855)
* Support for Extensible Priorities ([RFC 9218](https://www.rfc-editor.org/rfc/rfc9218.html)): [#3470](https://github.com/quic-go/quic-go/issues/3470)
* Support for httptrace: [#3342](https://github.com/quic-go/quic-go/issues/3342)
* Support for HTTP Trailers: [#2266](https://github.com/quic-go/quic-go/issues/2266)
