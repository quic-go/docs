---
title: Datagrams
toc: true
weight: 10
---

## The Unreliable Datagram Extension

Unreliable datagrams are not part of QUIC (RFC 9000) itself, but a feature that is added by a QUIC extension ([RFC 9221](https://datatracker.ietf.org/doc/html/rfc9221)). As other extensions, it can be negotiated during the handshake. Support can be enabled by setting the `quic.Config.EnableDatagram` flag. Note that this doesn't guarantee that the peer also supports datagrams. Whether or not the feature negotiation succeeded can be learned from the `ConnectionState.SupportsDatagrams` obtained from `Connection.ConnectionState()`.

QUIC DATAGRAMs are a new QUIC frame type sent in QUIC 1-RTT packets (i.e. after completion of the handshake). Therefore, they're end-to-end encrypted and congestion-controlled. However, if a DATAGRAM frame is deemed lost by QUIC's loss detection mechanism, they are not retransmitted.

## Sending and Receiving Datagrams

Datagrams are sent using the `SendDatagram` method on the `quic.Connection`:

```go
conn.SendDatagram([]byte("foobar"))
```

And received using `ReceiveDatagram`:

```go
msg, err := conn.ReceiveDatagram(context.Background())
```

Note that this code path is currently not optimized. It works for datagrams that are sent occasionally, but it doesn't achieve the same throughput as writing data on a stream. Please get in touch on issue #3766 if your use case relies on high datagram throughput, or if you'd like to help fix this issue.

## 📝 Future Work

* general performance improvements in the DATAGRAM send and receive path
* introduce an API to query the current DATAGRAM size limit: [#4259](https://github.com/quic-go/quic-go/issues/4259)
* notify the application when a DATAGRAM frame is acked / lost: [#4273](https://github.com/quic-go/quic-go/issues/4273)
