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

WebTransport enables web applications to establish bidirectional, multiplexed connections to servers, allowing for real-time communication and data streaming.

Support for WebTransport over HTTP/3 ([draft-ietf-webtrans-http3](https://datatracker.ietf.org/doc/draft-ietf-webtrans-http3/)) is implemented in [webtransport-go](https://github.com/quic-go/webtransport-go).

## Proxying UDP in HTTP (CONNECT-UDP)

Support for Proxying UDP in HTTP ([RFC 9298](https://datatracker.ietf.org/doc/html/rfc9298)), sometimes also called MASQUE or CONNECT-UDP,  is implemented in [masque-go](https://github.com/quic-go/masque-go).

## Proxying IP in HTTP (CONNECT-IP)

Support for Proxying IP in HTTP ([RFC 9484](https://datatracker.ietf.org/doc/html/rfc9484)), sometimes also called CONNECT-IP, is implemented in [connect-ip-go](https://github.com/quic-go/connect-ip-go).
