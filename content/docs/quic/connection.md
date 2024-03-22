---
title: Closing a Connection
toc: true
weight: 4
---

## Idle Timeouts

A QUIC connections can be closed automatically (i.e. without sending of any packets), if it is not used for a certain period of time, the so-called idle timeout. This is especially useful on mobile devices, where waking up the radio just to close a connection would be wasteful.

During the handshake, both client and server advertise the longest time that they want to keep the connection alive when it is idle. Details are specified in [Section 10.1 of RFC 9000](https://datatracker.ietf.org/doc/html/rfc9000#section-10.1). The idle timeout that applies to the connection is the minimum of the two values advertised by the client and by the server, respectively.

The idle timeout can be configured on a per-connection basis using the `MaxIdleTimeout` field on the `quic.Config`:
```go
quic.Config{
  MaxIdleTimeout: 45 * time.Second,
}
```

Internally, every QUIC connection endpoint keeps track of the time when the connection was last used, and silently (without sending any packets) closes the connection if that period exceeds the negotiated idle timeout period.

### Keeping a Connection Alive

Endpoints can prevent the idle timeout from closing a QUIC connection by regularly sending application data. However, an application can also request the QUIC stack to keep the connection alive. This is done by regularly sending a PING frame before the idle timeout expires.

Keep-Alives can be configured by setting the `KeepAlivePeriod` option on the `quic.Config`.
```go
quic.Config{
  KeepAlivePeriod: 30 * time.Second,
}
```

This will cause a PING frame to be sent _at least_ every `KeepAlivePeriod`. If the idle timeout negotiated between the two endpoints is shorter than the `KeepAlivePeriod`, PING frames will be sent more frequently.

## When the Remote Peer closes the Connection

In case the peer closes the QUIC connection, all calls to open streams, accept streams, as well as all methods on streams immediately return an error. Additionally, it is set as cancellation cause of the connection context. Users can use errors assertions to find out what exactly went wrong:

* `quic.VersionNegotiationError`: Happens during the handshake, if there is no overlap between our and the remote's supported QUIC versions.
* `quic.HandshakeTimeoutError`: Happens if the QUIC handshake doesn't complete within the time specified in `quic.Config.HandshakeTimeout`.
* `quic.IdleTimeoutError`: Happens after completion of the handshake if the connection is idle for longer than the minimum of both peers idle timeouts (as configured by `quic.Config.IdleTimeout`). The connection is considered idle when no stream data (and datagrams, if applicable) are exchanged for that period. The QUIC connection can be instructed to regularly send a packet to prevent a connection from going idle by setting `quic.Config.KeepAlive`. However, this is no guarantee that the peer doesn't suddenly go away (e.g. by abruptly shutting down the node or by crashing), or by a NAT binding expiring, in which case this error might still occur.
* `quic.StatelessResetError`: Happens when the remote peer lost the state required to decrypt the packet. This requires the `quic.Transport.StatelessResetToken` to be configured by the peer.
* `quic.TransportError`: Happens if when the QUIC protocol is violated. Unless the error code is `APPLICATION_ERROR`, this will not happen unless one of the QUIC stacks involved is misbehaving. Please open an issue if you encounter this error.
* `quic.ApplicationError`: Happens when the remote decides to close the connection, see below.

## When we close the Connection

A `quic.Connection` can be closed using `CloseWithError`:

```go
conn.CloseWithError(0x42, "error 0x42 occurred")
```

Applications can transmit both an error code (an unsigned 62-bit number) as well as a UTF-8 encoded human-readable reason. The error code allows the receiver to learn why the connection was closed, and the reason can be useful for debugging purposes.

On the receiver side, this is surfaced as a `quic.ApplicationError`.
