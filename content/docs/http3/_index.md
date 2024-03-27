---
title: HTTP/3
toc: true
weight: 2
---

While HTTP/1.1 and HTTP/2 both run on top of TCP connections, HTTP/3 is the HTTP version that runs on top of QUIC.

The [http3 package](https://github.com/quic-go/quic-go/tree/master/http3) of quic-go implements HTTP/3 ([RFC 9114](https://datatracker.ietf.org/doc/html/rfc9114)), including QPACK ([RFC 9204](https://datatracker.ietf.org/doc/html/rfc9204)).
It aims to provide feature parity with the standard library's HTTP/1.1 and HTTP/2 implementation.
