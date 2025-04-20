---
title: Connection Migration
toc: true
weight: 50
---

Whereas TCP identifies connection by their 4-tuple (i.e. the combination of the client's and server's IP address and port), QUIC uses connection IDs to demultiplex connections. This allows QUIC connections to migrate between paths.


This can be useful when a mobile phone moves away from a WiFi networks, and wishes to use the cellular connection instead. Connection migration is completely transparent to the application, as the entire connection, including all streams, is migrated to the new path.

{{< callout type="warning" >}}
  Note that there's a big difference between connection migration and multipath. Using connection migration, as defined in RFC 9000, only a single path can be used to send application at a time. The [Multipath Extension for QUIC]({{< relref path="multipath.md" >}}) describes the framing layer for multipath usage of QUIC.
{{< /callout >}}

## Probing Paths

Before a new path (i.e. a new 4-tuple) can be used to send application data, QUIC needs to make sure that the path actualy works. This makes sure that the connection doesn't break after migration, and it defends against a variety of packet injection attacks.

To probe a path, the endpoint sends a PATH_CHALLENGE frame in a packet sent over the new path. Once the peer receives the PATH_CHALLENGE frame, it responds with a PATH_RESPONSE frame (not necessarily on the same path), which confirms that the path is works.

Path probing packets use fresh connection IDs, which prevents an on-path observer from linking the new to the old path.

## Probing and Switching Paths

According to RFC 9000, connection migration is always initiated by the client. With the exception of the Preferred Address mechanism (see below), there is no way for the server to initiate - or even request - a migration.

Migrating a connection is a two-step process:
1. The client needs to probe the new path, in order to make sure that it can actually be used to send application data.
2. At some later point, the client can then decide to switch the connection to the new path.

To create a new path, the it is necessary to create a new `quic.Transport` that is used to send packets for the new path. For example, the client might want to migrate a connection from WiFi to cellular.

```go
tr1 := &quic.Transport{
  Conn: conn1, // for example: a connection bound to the WiFi interface
}
tr2 := &quic.Transport{
  Conn: conn2, // for example: a connection bound to the cellular interface
}
var conn quic.Connection // connection established on tr1

path, err := conn.AddPath(tr2)
// ... error handling
```

This code does nothing more than creating a new `quic.Path`. No packets are sent over the new path yet.
Path probing is started by calling the `Probe` method on the `Path`.

```go
ctx, cancel := context.WithTimeout(context.Background(), time.Second)
defer cancel()
err := path.Probe(ctx)
// ... error handling
```

If the error returned by `Probe` is `nil`, the path has been successfully probed and the client can switch to the new path by calling `Switch`.
```go
err := path.Switch()
// ... error handling
```

From this point on, all application data sent on the connection will now be sent over the new path.

If the application decides that it doesn't need a path created with `AddPath`, it can clean up resources by calling the `Close` method on the `Path`:

```go
err := path.Close()
// ... error handling
```

## NAT Rebindings

A QUIC client might be located behind a NAT, i.e. a device that rewrites the client's IP address and port to a public IP address and port. This is often the case for devices in home or corporate networks. Sometimes, usually after periods of inactivity, the NAT might have garbage collected the old mapping, and create a new mapping for the same client. This is called a NAT Rebinding.

In TCP, this is an irrecoverable event, since the 4-tuple has changed. QUIC can recover from this by migrating the connection to the new 4-tuple.

Neither the client nor the server can predict when a NAT rebinding will happen. When the server receives a packet for an existing connection from a new IP address and port, it will need to probe the path to make sure that the client is still reachable. quic-go handles this automatically, no action is needed from the application.


## 📝 Future Work

* Support for Preferred Address: [#4965](https://github.com/quic-go/quic-go/issues/4965)
