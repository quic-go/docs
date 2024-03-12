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
