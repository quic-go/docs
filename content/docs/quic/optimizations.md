---
title: Optimizations
toc: true
weight: 20
---

## Generic Segmentation Offload (GSO) {#gso}

`net.UDPConn.WriteMsgUDP` sends a single UDP packet. Under the hood, the standard library uses the `sendmsg` syscall. In principle, this is all we need to make QUIC work. However, for high-troughput transfers, the cost of these syscalls adds up.

Generic Segmentation Offload (GSO) allows applications to pass a large (up to 64 kB) buffer to the kernel, and have the kernel chop this buffer up into smaller pieces. This comes with a few requirements: all packets are sent to the same receiver address, and all packets except the last one need to have exactly the same size. quic-go handles all this complexity, and is able to optimize the creation of new packets by creating them in GSO-sized batched.

GSO is currently only available on Linux for kernel versions from 4.18. On certain systems, GSO might still fail, which is why quic-go comes with GSO detection logic, and falls back to the non-GSO send path if GSO doesn't properly work.

There is no config flag to disable GSO support, and it is not expected that users would ever want to disable GSO support. If you run into any GSO-related problem, please open an issue. It is however possible to globally disable GSO by setting the `QUIC_GO_DISABLE_GSO` environment variable to `true`.

### 📝 Future Work

* GSO on Windows: [#4325](https://github.com/quic-go/quic-go/issues/4325)
* amortize header protection cost by batching: [#4371](https://github.com/quic-go/quic-go/issues/4371)

## UDP Buffer Sizes

Experiments have shown that QUIC transfers on high-bandwidth connections can be limited by the size of the UDP receive and send buffer. The receive buffer holds packets that have been received by the kernel, but not yet read by the application (quic-go in this case). The send buffer holds packets that have been sent by quic-go, but not sent out by the kernel. In both cases, once these buffers fill up, the kernel will drop any new incoming packet.

Therefore, quic-go tries to increase the buffer size. The way to do this is OS-specific, and we currently have an implementation for Linux, Windows and macOS. However, an application is only allowed to do increase the buffer size up to a maximum value set in the kernel. Unfortunately, on Linux this value is rather small, too small for high-bandwidth QUIC transfers.

### non-BSD

It is recommended to increase the maximum buffer size by running:
```
sysctl -w net.core.rmem_max=2500000
sysctl -w net.core.wmem_max=2500000
```
This command would increase the maximum send and the receive buffer size to roughly 2.5 MB. Note that these settings are not persisted across reboots.

### BSD

Taken from: https://medium.com/@CameronSparr/increase-os-udp-buffers-to-improve-performance-51d167bb1360

> On BSD/Darwin systems you need to add about a 15% padding to the kernel limit socket buffer. Meaning if you want a 25MB buffer (8388608 bytes) you need to set the kernel limit to 26214400*1.15 = 30146560.

To update the value immediately to 2.5M, type the following commands as root:
```sh
sysctl -w kern.ipc.maxsockbuf=3014656
```
Add the following lines to the `/etc/sysctl.conf` file to keep this setting across reboots:
```
kern.ipc.maxsockbuf=3014656
```

### 📝 Open Questions

* Setting UDP buffer sizes when using Docker: [#3801](https://github.com/quic-go/quic-go/issues/3801) 
* Setting UDP buffer sizes on OpenBSD: [#3476](https://github.com/quic-go/quic-go/issues/3476)


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

### 📝 Future Work

* Handle decreasing MTUs: [#3955](https://github.com/quic-go/quic-go/issues/3955)
* Make the maximum packet size configurable: [#3385](https://github.com/quic-go/quic-go/issues/3385)
