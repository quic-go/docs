---
title: The quic-go Protocol Suite
toc: true
---

## QUIC

[quic-go](https://github.com/quic-go/quic-go) is an optimized, production-ready implementation of the QUIC protocol ([RFC 9000](https://datatracker.ietf.org/doc/html/rfc9000), [RFC 9001](https://datatracker.ietf.org/doc/html/rfc9001), [RFC 9002](https://datatracker.ietf.org/doc/html/rfc9002)), including several QUIC extensions.

## HTTP/3

quic-go also has support for HTTP/3 ([RFC 9114](https://datatracker.ietf.org/doc/html/rfc9114)), including QPACK ([RFC 9204](https://datatracker.ietf.org/doc/html/rfc9204)) and HTTP Datagrams ([RFC 9297](https://datatracker.ietf.org/doc/html/rfc9297)).

With this package, it is possible to run a Go server that serves HTTP/1.1, HTTP/2 and HTTP/3.

## WebTransport

Support for WebTransport over HTTP/3 ([draft-ietf-webtrans-http3](https://datatracker.ietf.org/doc/draft-ietf-webtrans-http3/)) is implemented in [webtransport-go](https://github.com/quic-go/webtransport-go).

## MASQUE

Support for Proxying UDP in HTTP ([RFC 9298](https://datatracker.ietf.org/doc/html/rfc9298)) will be added soon.
