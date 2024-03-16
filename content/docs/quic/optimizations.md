---
title: Optimizations
toc: true
weight: 5
---

## Generic Segmentation Offload (GSO)

`net.UDPConn.WriteMsgUDP` sends a single UDP packet. Under the hood, the standard library uses the `sendmsg` syscall. In principle, this is all we need to make QUIC work. However, for high-troughput transfers, the cost of these syscalls adds up.

Generic Segmentation Offload (GSO) allows applications to pass a large (up to 64 kB) buffer to the kernel, and have the kernel chop this buffer up into smaller pieces. This comes with a few requirements: all packets are sent to the same receiver address, and all packets except the last one need to have exactly the same size. quic-go handles all this complexity, and is able to optimize the creation of new packets by creating them in GSO-sized batched.

GSO is currently only available on Linux for kernel versions from 4.18. On certain systems, GSO might still fail, which is why quic-go comes with GSO detection logic, and falls back to the non-GSO send path if GSO doesn't properly work.

There is no config flag to disable GSO support, and it is not expected that users would ever want to disable GSO support. If you run into any GSO-related problem, please open an issue. It is however possible to globally disable GSO by setting the `QUIC_GO_DISABLE_GSO` environment variable to `true`.

### Future Work

* GSO on Windows
* amortize header protection cost

## Path MTU Discovery (DPLPMTUD)

RFC 9000 requires any QUIC path to support MTUs of at least 1200 bytes, but many paths on the internet support larger MTUs, some up to 1500 bytes. On some path, even larger MTUs are possible.

Datagram Packetization Layer Path MTU Discovery (DPLPMTUD) allows a QUIC endpoint to determine the MTU available on a given path, and therefore increase the size of QUIC packets it sends. This is advantageus since there is a per-packet overhead: QUIC packet encryption, QUIC header protection, framing overhead, etc.

DPLPMTUD is enabled by default. If desired, it can be disabled on a per-connection basis using the `quic.Config`:
```go
quic.Config{
  DisablePathMTUDiscovery: false,
}
```

DPLPMTUD works by occasionally sending larger "probe packets". If these packets are received and acknowledged, this confirms that the network path is capable of handling higher MTUs, and allows quic-go to increase the size of packets sent out. In terms of bandwidth consumption, DPLPMTUD is exceedingly cheap: over the lifetime of a connection, less than 10 probe packets are sent.

### Future Work

* Handle decreasing MTUs
