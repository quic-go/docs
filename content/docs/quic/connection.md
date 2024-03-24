---
title: Closing a Connection
toc: true
weight: 4
---

## Idle Timeouts {#idle-timeout}

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


## Inspecting the Error

In case the peer closes the QUIC connection, all calls to open streams, accept streams, as well as all methods on streams immediately return an error. Additionally, it is set as cancellation cause of the connection context. In most cases, applications won't need to closely inspect the error returned. 

The most common way to handle an error is by interface-asserting it to `net.Error`, and (for example) retry the last operation if it's a temporary error.

The following example shows how to inspect an error in detail:

```go
var (
  statelessResetErr   *quic.StatelessResetError
  handshakeTimeoutErr *quic.HandshakeTimeoutError
  idleTimeoutErr      *quic.IdleTimeoutError
  appErr              *quic.ApplicationError
  transportErr        *quic.TransportError
  vnErr               *quic.VersionNegotiationError
)
switch {
case errors.As(err, &statelessResetErr):
  // stateless reset
case errors.As(err, &handshakeTimeoutErr):
  // connection timed out before completion of the handshake
case errors.As(err, &idleTimeoutErr):
  // idle timeout
case errors.As(err, &appErr):
  // application error
  remote := appErr.Remote             // was the error triggered by the peer?
  errorCode := appErr.ErrorCode       // application-defined error code
  errorMessage := appErr.ErrorMessage // application-defined error message
case errors.As(err, &transportErr):
  // transport error
  remote := transportErr.Remote             // was the error triggered by the peer?
  errorCode := transportErr.ErrorCode       // error code (RFC 9000, section 20.1)
  errorMessage := transportErr.ErrorMessage // error message
case errors.As(err, &vnErr):
  // version negotation error
  ourVersions := vnErr.Ours     // locally supported QUIC versions
  theirVersions := vnErr.Theirs // QUIC versions support by the remote
}
```

* `quic.VersionNegotiationError`: Happens during the handshake, if [Version Negotiation]({{< relref "transport.md#version-negotiation" >}}) fails, i.e. when there is no overlap between the client's and the server's supported QUIC versions.
* `quic.HandshakeTimeoutError`: Happens if the QUIC handshake doesn't complete within the time specified in `quic.Config.HandshakeTimeout`.
* `quic.IdleTimeoutError`: Happens after completion of the handshake if the connection is [idle](#idle-timeout) for longer than the minimum of both peers idle timeouts.
* `quic.StatelessResetError`: Happens when a [Stateless Reset]({{< relref "transport.md#stateless-reset" >}}) is received.
* `quic.TransportError`: Happens if the QUIC protocol is violated. Unless the error code is `APPLICATION_ERROR`, this will not happen unless one of the QUIC stacks involved is misbehaving. Please open an issue if you encounter this error.
* `quic.ApplicationError`: Happens when the remote decides to close the connection, see below.

## When we close the Connection

A `quic.Connection` can be closed using `CloseWithError`:

```go
conn.CloseWithError(0x42, "error 0x42 occurred")
```

Applications can transmit both an error code (an unsigned 62-bit number) as well as a UTF-8 encoded human-readable reason. The error code allows the receiver to learn why the connection was closed, and the reason can be useful for debugging purposes.

On the receiver side, this is surfaced as a `quic.ApplicationError`.
