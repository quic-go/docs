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
