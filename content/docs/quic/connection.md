---
title: QUIC Connection
toc: true
weight: 4
---

The `quic.Connection` is the central object to send and receive application data. Data is not sent directly on the connection, but either on [streams]({{< relref "streams.md" >}}), or (optionally) in so-called [datagrams]({{< relref "datagrams.md" >}}).


## Using the Connection Context {#conn-context}

When a new QUIC connection is established, a number of callbacks might be called during the different stages of the QUIC handshake. Among those are:
* TLS configuration callbacks, e.g. `tls.Config.GetConfigForClient`, `tls.Config.GetCertificate` and `tls.Config.GetClientCertificate`
* QUIC connection tracer configuration (using `quic.Config.Tracer`), used for configuring [qlog event logging]({{< relref "qlog.md" >}}), among others

Applications can identify which QUIC connection these callbacks are called for by attaching values to the context using `Transport.ConnContext` (for incoming connections) and the context passed to `Dial` (for outgoing connections).

For example:
```go
tr := quic.Transport{
  ConnContext: func(ctx context.Context, info *quic.ClientInfo) (context.Context, error) {
    // In practice, generate an identifier that's unique to this one connection,
    // for example by incrementing a counter.
    return context.WithValue(ctx, "foo", "bar"), nil
  }
}

ln, err := tr.Listen(&tls.Config{
  GetConfigForClient: func(info *tls.ClientHelloInfo) *tls.Config {
    // this context has a key "foo" with value "bar"
    _ = info.Context()
    return <tls.Config>
  }
}, nil)
// ... error handling
conn, err := ln.Accept()
// ... error handling

// this context has a key "foo" with value "bar"
_ = conn.Context()
```

The context passed to `ConnContext` is closed once the QUIC connection is closed, or if the handshake fails for any reason.
This allows applications to clean up state that might they might have created in the `ConnContext` callback (e.g. by using `context.AfterFunc`).

{{< callout type="info" >}}
  By returning an error, `ConnContext` can also be used to reject a connection attempt at a very early stage, before the QUIC handshake is started.
{{< /callout >}}

## Closing a Connection {#closing}

At any point during the connection, a `quic.Connection` can be closed by calling `CloseWithError`:

```go
conn.CloseWithError(0x42, "I don't want to talk to you anymore 🙉")
```

Error codes are defined by the application and can be any unsigned 62-bit value. The error message is a UTF-8 encoded human-readable reason. The error code allows the receiver to learn why the connection was closed, and the reason can be useful for debugging purposes.
quic-go doesn't provide a way to close a connection without providing an error code or an error message.

{{< callout type="warning" >}}
  This instantly closes the connection. There's no guarantee that any outstanding stream data or datagrams will be delivered.
  In particular, writing to a stream, closing the stream, and immediately closing the connection doesn't guarantee that the peer has received all stream data.

  The application is responsible for ensuring that all data has been delivered before closing the connection.
{{< /callout >}}

Closing the connections makes all calls associated with this connection (accepting and opening streams, reading and writing on streams, sending and receiving datagrams, etc.) return immediately. On the receiver side, the error is surfaced as a `quic.ApplicationError` as soon as it is received.

{{< callout type="warning" >}}
  If the connection is closed before the handshake completes, the error code might not be transmitted to the peer.

  Instead the error might be surfaced as a `quic.TransportError` with an APPLICATION_ERROR error code. This protects from application state being revealed unencrypted on the wire. See [Section 10.2.3 of RFC 9000](https://datatracker.ietf.org/doc/html/rfc9000#section-10.2.3) for details.
{{< /callout >}}


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

Endpoints can prevent the idle timeout from closing a QUIC connection by regularly sending application data. However, an application can also request the QUIC stack to keep the connection alive. This is done by regularly sending a PING frame before the idle timeout expires. A PING frame is a mechanism in QUIC used purely to elicit an acknowledgment from the peer, ensuring the connection is considered active.

Keep-Alives can be configured by setting the `KeepAlivePeriod` option on the `quic.Config`.
```go
quic.Config{
  KeepAlivePeriod: 30 * time.Second,
}
```

This will cause a PING frame to be sent _at least_ every `KeepAlivePeriod`. If the idle timeout negotiated between the two endpoints is shorter than the `KeepAlivePeriod`, PING frames will be sent more frequently.

{{< callout type="warning" >}}
  Enabling Keep-Alives doesn't mean that the connection can't experience an idle timeout. For example, the remote node could have crashed, or the path could have become unusable for a number of reasons.
{{< /callout >}}


## Inspecting the Error {#error-assertion}

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
* `quic.ApplicationError`: Happens when the remote decides to close the connection, see above.

## 📝 Future Work

* Better Configuration of Keep-Alives: [#4382](https://github.com/quic-go/quic-go/issues/4382)
