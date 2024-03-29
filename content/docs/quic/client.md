---
title: Running a QUIC Client
toc: true
weight: 3
---

## Using a `quic.Transport`

Since QUIC uses connection IDs to demultiplex connections, multiple outgoing connections can share a single UDP socket.

```go
ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second) // 3s handshake timeout
defer cancel()
conn, err := tr.Dial(ctx, <server address>, <tls.Config>, <quic.Config>)
// ... error handling
```


## Using the Convenience Functions

As a shortcut, `quic.Dial` and `quic.DialAddr` can be used without explictly initializing a `quic.Transport`:

```go
ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second) // 3s handshake timeout
defer cancel()
conn, err := quic.Dial(ctx, conn, <server address>, <tls.Config>, <quic.Config>)
```

Just as we saw before when used a similar shortcut to run a server, it's also not possible to reuse the same UDP socket for other outgoing connections, or to listen for incoming connections.


## TLS Session Resumption {#tls-session-resumption}

Just as a TLS client running on top of a TCP connection, a QUIC client can also use [TLS session resumption](https://datatracker.ietf.org/doc/html/rfc8446#section-2.2). Session resumption allows the skipping of certain parts of the TLS handshake. For example, the server doesn't need to send its certificate again.

To use session resumption, nothing needs to be done on the QUIC layer. It is enabled the same way as when using the standard library TLS over TCP, i.e. by settings the `tls.Config.ClientSessionCache`.


## 0-RTT

QUIC's 0-RTT feature allows the client to send application data right away when resuming a connection to a server to which it connected before. Application data is sent before the handshake with the server completes.

```mermaid
sequenceDiagram
    Client->>Server: ClientHello
    activate Client
    rect rgb(220,220,220)
    Client-->>Server: 0-RTT Application data
    activate Server
    end
    deactivate Client
    Server->> Client: ServerHello, Certificate, Finished
    activate Client
    rect rgb(220,220,220)
    Server-->>Client: 0.5-RTT Application data
    end
    deactivate Server
    Client->>Server: (Client Certificates), Finished
    activate Server
    rect rgb(220,220,220)
    Client-->>Server: 1-RTT Application Data
    deactivate Client
    Server-->>Client: 1-RTT Application Data
    end
    deactivate Server
```


A client can use 0-RTT session resumption if a few conditions are met on the client side:
1. It needs to use [TLS session resumption](#tls-session-resumption). There's no way to use 0-RTT without a TLS session ticket.
2. The server's support for session resumption, indicated by the session ticket issued on the initial connection, must be present.
3. The ALPN (configured using `tls.Config.NextProtos`) on the new connection must be the same.

{{< callout type="warning" >}}
  Due to the design of the TLS protocol, clients cannot directly request session tickets or unilaterally enable 0-RTT. These capabilities depend on the server's configuration and support.
{{< /callout >}}

To dial a 0-RTT connection, use `DialEarly` instead of `Dial`. quic-go performs the checks for the conditions listed above and dials a 0-RTT connection if they are met.

```go
ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
defer cancel()
tlsConf := &tls.Config{
  ClientSessionCache: tls.NewLRUClientSessionCache(100),
}
// 1. Use this tls.Config to establish the first connection to the server
// and receive a session ticket ...
// 2. Dial another connection to the same server
conn, err := tr.DialEarly(ctx, <server address>, tlsConf, <quic.Config>)
// ... error handling
// Check if 0-RTT is being used
uses0RTT := conn.ConnectionState().Used0RTT
// If 0-RTT was used, DialEarly returned immediately.
// Open a stream and send some application data in 0-RTT ...
str, err := conn.OpenStream()
```


### Security Properties of 0-RTT

As described in [Section 8 of RFC 8446](https://datatracker.ietf.org/doc/html/rfc8446#section-8), application data sent in 0-RTT (what TLS 1.3 calls "Early Data") has different security properties than application data sent after completion of the handshake. 0-RTT data is encrypted, and an observer won't be able to decrypt it. However, since data is sent before the client has received any fresh key material from the server, an attacker can record the 0-RTT data and replay it to the server at a later point, or to a different server in a load-balanced server deployment.

In general it is only safe to perform idempotent actions in 0-RTT. It is the client's responsibility to make sure that the data it sends is appropriate to send in 0-RTT. For many application protocols, this means limiting to the use of 0-RTT to certain kinds of data, and delaying the sending of other data until the handshake has completed.

This can easily be accomplished by blocking on the channel returned by `HandshakeComplete`.
```go
select {
case <-conn.HandshakeComplete():
  // Handshake complete.
  // All data sent from here on is protected against replay attacks.
case <-conn.Context().Done():
  // Handshake failed.
}
```


## 📝 Future Work

* Mitigate [Performance Impact of Large Certificates]({{< relref "server.md#cert-size" >}}) by sending two ClientHellos: [#3775](https://github.com/quic-go/quic-go/issues/3775)
* Happy Eyeballs for `DialAddr`: [#3772](https://github.com/quic-go/quic-go/issues/3772)
