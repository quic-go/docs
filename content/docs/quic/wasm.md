---
title: WASM
toc: true
weight: 99
---

It is possible to compile an application using quic-go to WASM.

Since the `wasip1` API [lacks support](https://go.dev/blog/wasi) for network sockets, it's necessary to create the UDP socket using the [WASI socket extension](https://github.com/dispatchrun/net).


```go
import "github.com/stealthrocket/net/wasip1"

conn, err := wasip1.ListenPacket("udp", "127.0.0.1:443")
// ... handle error ...
ln, err := quic.Listen(conn, <tls.Config>, <quic.Config>)
```

Note that `wasip1.ListenPacket` returns a `net.PacketConn`, not a `*net.UDPConn`, which means that quic-go won't be able to use [optimizations]({{< relref path="optimizations.md" >}}) like GSO or ECN.

The code can then be compiled to wasm and run using [`wasirun`](https://github.com/dispatchrun/wasi-go):
```sh
GOOS=wasip1 GOARCH=wasm go build -o myapp
wasirun ./myapp
```

It is currently not possible to use `wasmedge`, since it [doesn't allow](https://github.com/dispatchrun/net/issues/34) sending of UDP datagrams.


## Limitations

It is not possible to use convenience functions like `quic.ListenAddr` and `quic.DialAddr`, since these functions create the UDP socket using the standard library `net` package.


## 📝 Future Work

* Improve WASM support: [#4524](https://github.com/quic-go/quic-go/issues/4524)
