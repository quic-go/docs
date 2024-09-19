---
title: MASQUE
toc: true
weight: 4
---

CONNECT-UDP ([RFC 9298](https://datatracker.ietf.org/doc/html/rfc9298))enables the proxying of UDP packets over HTTP/3. It is being implemented in [masque-go](https://github.com/quic-go/masque-go).

A CONNECT-UDP client establishes an HTTP/3 connection to a proxy and requests the proxying to a remote server. UDP datagrams are then sent using HTTP Datagrams ([RFC 9279](https://datatracker.ietf.org/doc/html/rfc9298)).


