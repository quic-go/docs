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

## 📝 Future Work

* Graceful shutdown: [#153](https://github.com/quic-go/quic-go/issues/153)
* Correctly deal with 0-RTT and HTTP/3 extensions: [#3855](https://github.com/quic-go/quic-go/issues/3855)
* Support for Extensible Priorities ([RFC 9218](https://www.rfc-editor.org/rfc/rfc9218.html)): [#3470](https://github.com/quic-go/quic-go/issues/3470)
* Support for httptrace: [#3342](https://github.com/quic-go/quic-go/issues/3342)
* Support for HTTP Trailers: [#2266](https://github.com/quic-go/quic-go/issues/2266)
