---
title: Dialing HTTP/3
toc: true
weight: 2
---

This package provides a `http.RoundTripper` implementation that can be used on the `http.Client`:

```go
roundTripper := &http3.RoundTripper{
	TLSClientConfig: &tls.Config{},  // set a TLS client config, if desired
	QUICConfig:      &quic.Config{}, // QUIC connection options
}
defer roundTripper.Close()
client := &http.Client{
	Transport: roundTripper,
}
```

The `http.Client` can then be used to perform HTTP requests over HTTP/3.


## Using a `quic.Transport`

To use a custom `quic.Transport`, the function used to dial new QUIC connections can be configured:
```go
tr := quic.Transport{}
roundTripper := &http3.RoundTripper{
	TLSClientConfig: &tls.Config{},  // set a TLS client config, if desired 
	QUICConfig:      &quic.Config{}, // QUIC connection options 
	Dial: func(ctx context.Context, addr string, tlsConf *tls.Config, quicConf *quic.Config) (quic.EarlyConnection, error) {
		a, err := net.ResolveUDPAddr("udp", addr)
		if err != nil {
			return nil, err
		}
		return tr.DialEarly(ctx, a, tlsConf, quicConf)
	},
}
```

This gives the application more fine-grained control over the configuration of the `quic.Transport`.


## Using the same UDP Socket for Server and Roundtripper

Since QUIC demultiplexes packets based on their connection IDs, it is possible allows running a QUIC server and client on the same UDP socket. This also works when using HTTP/3: HTTP requests can be sent from the same socket that a server is listening on.

To achieve this using this package, first initialize a single `quic.Transport`, and pass a `quic.EarlyListner` obtained from that transport to `http3.Server.ServeListener`, and use the `DialEarly` function of the transport as the `Dial` function for the `http3.RoundTripper`.

## Using 0-RTT

The use of 0-RTT was not anticipated by Go's standard library, and Go doesn't have 0-RTT support, neither in its `crypto/tls` nor in its `net/http` implementation (not even for TLS 1.3 on top of TCP). The `http3` package therefore defines two new request methods: `http3.MethodGet0RTT` for GET requests and `http3.MethodHead0RTT` for HEAD requests.

{{< callout type="warning" >}}
  Support for the "Early-Data" header field, as well as the "Too Early" status code (425) defined in [RFC 8470](https://datatracker.ietf.org/doc/html/rfc8470#section-5.2) is not yet implemented. See [📝 Future Work](#future-work).
{{< /callout >}}

It is the application's responsibility to make sure that it is actually safe to send a request in 0-RTT, as outlined in [Security Properties of 0-RTT]({{< relref "../quic/client.md#0rtt-security" >}}). Requests sent in 0-RTT can be replayed on a new connection by an on-path attacker, so 0-RTT should only be used for idempotent requests. [RFC 8740](https://datatracker.ietf.org/doc/html/rfc8470) defines some guidance on how to use 0-RTT in HTTP.


```go
rt := &http3.RoundTripper{
	TLSClientConfig: &tls.Config{
		ClientSessionCache: tls.NewLRUClientSessionCache(100),
	},
}
req, err := http.NewRequest(http3.MethodGet0RTT, "https://my-server/path", nil)
// ... handle error ...
rt.RoundTrip(req)
```

The code snippet shows all the knobs that need to be turned to send a request in 0-RTT data:
1. TLS session resumption must be enabled by configuring a `tls.ClientSessionCache` on the `tls.Config`.
2. The request method needs to be set to `http3.MethodGet0RTT`.

## 📝 Future Work {#future-work}

* Support for zstd Content Encoding: [#4100](https://github.com/quic-go/quic-go/issues/4100)
* qlog Support: [#4124](https://github.com/quic-go/quic-go/issues/4124)
* Happy Eyeballs Support: [#3755](https://github.com/quic-go/quic-go/issues/3755)
* Support for Extensible Priorities ([RFC 9218](https://www.rfc-editor.org/rfc/rfc9218.html)): [#3470](https://github.com/quic-go/quic-go/issues/3470)
* Support for HTTP Trailers: [#2266](https://github.com/quic-go/quic-go/issues/2266)
* Use [`Early-Data` header field](https://datatracker.ietf.org/doc/html/rfc8470#section-5.1) for 0-RTT requests, retry on 425 response status: [#4381](https://github.com/quic-go/quic-go/issues/4381)
