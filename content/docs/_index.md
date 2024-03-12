---
title: Docs
toc: true
---

quic-go is an implementation of the QUIC protocol ([RFC 9000](https://datatracker.ietf.org/doc/html/rfc9000), [RFC 9001](https://datatracker.ietf.org/doc/html/rfc9001), [RFC 9002](https://datatracker.ietf.org/doc/html/rfc9002)) in Go. It has support for HTTP/3 ([RFC 9114](https://datatracker.ietf.org/doc/html/rfc9114)), including QPACK ([RFC 9204](https://datatracker.ietf.org/doc/html/rfc9204)).

In addition to these base RFCs, it also implements the following RFCs: 
* Unreliable Datagram Extension ([RFC 9221](https://datatracker.ietf.org/doc/html/rfc9221))
* Datagram Packetization Layer Path MTU Discovery (DPLPMTUD, [RFC 8899](https://datatracker.ietf.org/doc/html/rfc8899))
* QUIC Version 2 ([RFC 9369](https://datatracker.ietf.org/doc/html/rfc9369))
* QUIC Event Logging using qlog ([draft-ietf-quic-qlog-main-schema](https://datatracker.ietf.org/doc/draft-ietf-quic-qlog-main-schema/) and [draft-ietf-quic-qlog-quic-events](https://datatracker.ietf.org/doc/draft-ietf-quic-qlog-quic-events/))

Support for WebTransport over HTTP/3 ([draft-ietf-webtrans-http3](https://datatracker.ietf.org/doc/draft-ietf-webtrans-http3/)) is implemented in [webtransport-go](https://github.com/quic-go/webtransport-go).
