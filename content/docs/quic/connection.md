---
title: Closing a Connection
toc: true
weight: 4
---

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
