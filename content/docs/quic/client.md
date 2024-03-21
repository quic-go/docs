---
title: Running a QUIC Client
toc: true
weight: 3
---

Since QUIC uses connection IDs to demultiplex connections, multiple outgoing connections can share a single UDP socket.

```go
ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second) // 3s handshake timeout
defer cancel()
conn, err := tr.Dial(ctx, <server address>, <tls.Config>, <quic.Config>)
// ... error handling
```

As a shortcut, `quic.Dial` and `quic.DialAddr` can be used without explictly initializing a `quic.Transport`:

```go
ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second) // 3s handshake timeout
defer cancel()
conn, err := quic.Dial(ctx, conn, <server address>, <tls.Config>, <quic.Config>)
```

Just as we saw before when used a similar shortcut to run a server, it's also not possible to reuse the same UDP socket for other outgoing connections, or to listen for incoming connections.

## TLS Session Resumption

Just as a TLS client running on top of a TCP connection, a QUIC client can also use [TLS session resumption](https://datatracker.ietf.org/doc/html/rfc8446#section-2.2). Session resumption allows the skipping of certain parts of the TLS handshake. For example, the server doesn't need to send its certificate again.

To use session resumption, nothing needs to be done on the QUIC layer. It is enabled the same way as when using the standard library TLS over TCP, i.e. by settings the `tls.Config.ClientSessionCache`.

