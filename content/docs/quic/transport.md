---
title: Transport
toc: true
weight: 1
---

## Initializing a Transport

The central entrypoint into quic-go is the `quic.Transport`. It used both when running a QUIC server and when dialing QUIC connections.

Other than TCP, which identifies connections by their 4-tuple (i.e. the combination of the client's and server's IP address and port), QUIC uses connection IDs to demultiplex connections. That means that an arbitrary number of QUIC connections can be run on the same UDP socket. It is even possible to run a server (accepting incoming connections) and clients (establishing outgoing connections) on the socket.

The following code creates a new `quic.Transport` that uses UDP port 6121 on all available interfaces.
```go
addr, err := net.ResolveUDPAddr("udp", "0.0.0.0:6121")
// ... error handling
conn, err := net.ListenUDP("udp", addr)
// ... error handling
tr := &quic.Transport{
  Conn: conn,
}
```

As a rule of thumb, it is only necessary to create separate `quic.Transport`s when listening on multiple UDP ports, or when binding sockets to different network interfaces.

{{< callout type="warning" >}}
  Keep in mind that to achieve decent transfer performance, you might need to increase the kernel's [UDP send and receive buffer]({{< relref path="optimizations.md#udp-buffer-sizes" >}}) size.
{{< /callout >}}

## Using a `net.PacketConn` that's not a `*net.UDPConn`

`Transport.Conn` is a `net.PacketConn`, allowing applications to use their own implementation of the `net.PacketConn` interface. With this, it is possible to do QUIC over transports other than UDP.

However, if the `net.PacketConn` is indeed a wrapped `*net.UDPConn`, this could prevent quic-go from accessing kernel-based optimizations, leading to reduced transfer performance. For example, using ECN is only possible if the packets sent are actual UDP packets.

Applications can test if their `net.PacketConn` implementation provides the required methods to enable these optimizations by using the `OOBCapablePacketConn` interface:
```go
type myPacketConn struct{}

var _ quic.OOBCapablePacketConn = &myPacketConn{}
```

## Handling non-QUIC packets

QUIC was designed to be demultiplexed with a number of common UDP-based protocols (see [RFC 9443](https://datatracker.ietf.org/doc/html/rfc9443) for details). This is achieved by inspecting the first few bits of every incoming UDP packet.

```go
tr.ReadNonQUICPacket(ctx context.Context, b []byte) (int, net.Addr, error) 
```

Using the `ReadNonQUICPacket` method is preferable over implementation this inspection logic outside of quic-go, and passing a wrapped `net.PacketConn` to the `Transport`, as it allows quic-go to use a number of kernel-based optimization (e.g. GSO) that massively speed up QUIC transfers (see [Optimizations]({{< relref path="optimizations.md#gso" >}})).

## Stateless Resets {#stateless-reset}

QUIC is designed to prevent off-path attackers from disrupting connections, unlike TCP where such attackers can close connections using RST packets.

A problem arises when a QUIC endpoint is suddenly rebooted: It now receives QUIC packets for connections for which it doesn't possess the TLS session keys anymore. For the peer, it would be beneficial if the connection could immediately be closed. Otherwise, it would have to wait for an idle timeout to occur.

Stateless resets, as outlined in [Section 10.3 of RFC 9000](https://datatracker.ietf.org/doc/html/rfc9000#section-10.3), address this issue. Utilizing a static key and the connection ID from an incoming packet, a rebooted endpoint generates a 16-byte stateless reset token. This token is sent in a packet mimicking a standard QUIC packet. The peer, already aware of the stateless reset token linked to the connection ID, recognizes the stateless reset and can close the connection instantly.

The key used to calculate stateless reset tokens is configured on the `quic.Transport`:
```go
// load the key from disk, or derive it deterministically
var statelessResetKey quic.StatelessResetKey
quic.Transport{
  StatelessResetKey: &statelessResetKey,
}
```

Applications need to make sure that this key stays constant across reboots of the endpoint. One way to achieve this is to load it from a configuration file on disk. Alternatively, an application could also derive it from the TLS private key. Keeping this key confidential is essential to prevent off-path attackers from disrupting QUIC connections managed by the endpoint.


## Version Negotiation {#version-negotiation}

QUIC is designed to accommodate the definition of new versions in the future. [RFC 8999](https://datatracker.ietf.org/doc/html/rfc8999) describes the (minimal set of) properties of QUIC that must be fulfilled by all QUIC versions.

Before accepting a client's QUIC connection attempt, the server checks if it supports the QUIC version offered by the client. If it doesn't, it sends a Version Negotiation packet ([Section 6 of RFC 8999](https://datatracker.ietf.org/doc/html/rfc8999#section-6)), which lists all the versions supported by the server. The client can then pick a QUIC version that is supported by both nodes and initiate another connection attempt.


### QUIC Version 2
  
QUIC Version 2 was defined in [RFC 9369](https://datatracker.ietf.org/doc/html/rfc9369). It introduces no new features compared to QUIC Version 1 ([RFC 9000](https://datatracker.ietf.org/doc/html/rfc9000)), but has a slightly different wire image. It aims to acclimate middleboxes to the fact that QUIC is not just a single version. This will (hopefully!) prevent ossification and make it possible to define new versions of QUIC later.


### Configuring Versions

quic-go currently supports both QUIC version 1 and 2. The supported versions can be configured using the `Versions` field on the `quic.Config`.

```go
quic.Config{
  Versions: []quic.Version{quic.Version2, quic.Version1},
}
```

For the client, the first version in the `Versions` slice is used when dialing a new connection. The remaining versions are only used if the server doesn't support the first version and sends Version Negotiation packet. For the server, the order of the versions doesn't have any meaning.

By default, quic-go supports both versions, but prefers version 1, as this is the most commonly deployed QUIC version at this time.

### Disabling Version Negotiation

In certain deployments, clients know for a fact which QUIC versions a server supports. For example, in a p2p setting, a server might have advertised the supported QUIC versions in / with its address. In these cases, QUIC's version negotiation doesn't serve any purpose, but may expose the network to request forgery attacks as described in [Section 21.5.5 of RFC 9000](https://datatracker.ietf.org/doc/html/rfc9000#section-21.5.5).

The sending of Version Negotiation packets can be disabled using the `DisableVersionNegotiationPackets` option:
```go
quic.Transport{
  DisableVersionNegotiationPackets: true,
}
```

## 📝 Future Work

* Compatible Version Negotiation [RFC 9368](https://datatracker.ietf.org/doc/html/rfc9369): [#3640](https://github.com/quic-go/quic-go/issues/3640)
