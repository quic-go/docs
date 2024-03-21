---
title: Dialing HTTP/3
toc: true
weight: 2
---

This package provides a `http.RoundTripper` implementation that can be used on the `http.Client`:

```go
&http3.RoundTripper{
	TLSClientConfig: &tls.Config{},  // set a TLS client config, if desired
	QuicConfig:      &quic.Config{}, // QUIC connection options
}
defer roundTripper.Close()
client := &http.Client{
	Transport: roundTripper,
}
```

The `http3.RoundTripper` provides a number of configuration options, please refer to the [documentation](https://pkg.go.dev/github.com/quic-go/quic-go/http3#RoundTripper) for a complete list.

To use a custom `quic.Transport`, the function used to dial new QUIC connections can be configured:
```go
tr := quic.Transport{}
roundTripper := &http3.RoundTripper{
	TLSClientConfig: &tls.Config{},  // set a TLS client config, if desired 
	QuicConfig:      &quic.Config{}, // QUIC connection options 
	Dial: func(ctx context.Context, addr string, tlsConf *tls.Config, quicConf *quic.Config) (quic.EarlyConnection, error) {
		a, err := net.ResolveUDPAddr("udp", addr)
		if err != nil {
			return nil, err
		}
		return tr.DialEarly(ctx, a, tlsConf, quicConf)
	},
}
```

## Using the same UDP Socket for Server and Roundtripper

Since QUIC demultiplexes packets based on their connection IDs, it is possible allows running a QUIC server and client on the same UDP socket. This also works when using HTTP/3: HTTP requests can be sent from the same socket that a server is listening on.

To achieve this using this package, first initialize a single `quic.Transport`, and pass a `quic.EarlyListner` obtained from that transport to `http3.Server.ServeListener`, and use the `DialEarly` function of the transport as the `Dial` function for the `http3.RoundTripper`.

## 📝 Future Work

* Support for zstd Content Encoding: [#4100](https://github.com/quic-go/quic-go/issues/4100)
* qlog Support: [#4124](https://github.com/quic-go/quic-go/issues/4124)
* Happy Eyeballs Support: [#3755](https://github.com/quic-go/quic-go/issues/3755)
* Support for Extensible Priorities ([RFC 9218](https://www.rfc-editor.org/rfc/rfc9218.html)): [#3470](https://github.com/quic-go/quic-go/issues/3470)
* Support for HTTP Trailers: [#2266](https://github.com/quic-go/quic-go/issues/2266)
