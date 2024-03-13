---
title: Running a QUIC Server
toc: true
weight: 2
---

The central entry point is the `quic.Transport`. A `Transport` manages QUIC connections running on a single UDP socket. Since QUIC uses Connection IDs, it can demultiplex a listener (accepting incoming connections) and an arbitrary number of outgoing QUIC connections on the same UDP socket.

```go
udpConn, err := net.ListenUDP("udp4", &net.UDPAddr{Port: 1234})
// ... error handling
tr := quic.Transport{
  Conn: udpConn,
}
ln, err := tr.Listen(tlsConf, quicConf)
// ... error handling
go func() {
  for {
    conn, err := ln.Accept()
    // ... error handling
    // handle the connection, usually in a new Go routine
  }
}()
```

The listener `ln` can now be used to accept incoming QUIC connections by (repeatedly) calling the `Accept` method (see below for more information on the `quic.Connection`).

As a shortcut,  `quic.Listen` and `quic.ListenAddr` can be used without explicitly initializing a `quic.Transport`:

```go
ln, err := quic.Listen(udpConn, tlsConf, quicConf)
```

When using the shortcut, it's not possible to reuse the same UDP socket for outgoing connections.


## Certificate Size Considerations

During the initial phase of the QUIC handshake, before validating the client's address, server response size is restricted to thrice the bytes received from the client, as outlined in [RFC 9000, Section 8](https://datatracker.ietf.org/doc/html/rfc9000#name-address-validation). This limitation helps prevent the use of QUIC servers in DDoS attack amplifications by ensuring a server cannot send an excessively large response to a potentially spoofed packet.

Given that the initial client packet is typically 1200 bytes, the server's response is capped at 3600 bytes. This cap includes the server's TLS certificate in its first response, and an oversized certificate can extend the handshake by an additional RTT. As large certificates are commonplace, optimizing the certificate chain's size is advisable to avoid handshake delays, supported by insights from [Fastly's research](https://www.fastly.com/blog/quic-handshake-tls-compression-certificates-extension-study).

