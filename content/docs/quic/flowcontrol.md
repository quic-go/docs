---
title: Flow Control
toc: true
weight: 7
---

This page outlines the flow control algorithms used by QUIC. Flow control ensures that a sender doesn't overwhelm the receiver with too much data (and too many new streams), if the receiver is not able to keep up with the sender's rate. This is essential to control the resource consumption of a QUIC connection. On the other hand, misconfiguration of flow control limits often is the reason for suboptimal performance (see the [BDP section](#bdp)).


## Flow Control for Data sent on Streams

Flow control for data sent on streams is described in [Section 4.1 of RFC 9000](https://datatracker.ietf.org/doc/html/rfc9000#section-4.1). QUIC imposes two separate limits: 
1. A per-stream limit, defining the maximum amount of data that can be sent on any stream.
2. A per-connection limit specifying the total amount of data that can sent across all streams.

The per-connection limit makes it possible to use relatively high per-stream limits, while avoiding to commit a large amount of memory. For example, a QUIC stack might configure a per-stream window of 5 MB and a per-connection limit of 10 MB. Even if the peer opens 100 streams at the same time, the maximum memory commitment is limit to 10 MB (and not 500 MB).


### Limiting the Memory Commitment

A malicious peer could send all stream data up the flow control limit, except for the very first byte of the stream. In that case, the receiver isn't able to consume any data, but will have to buffer the received data.

This attack scenario is hard to distinguish from normal packet loss, where the packet containing the missing bytes happened to be lost. The flow control limit places an upper bound on our memory commitment (plus some overhead for the tracking data structures used).


### Relationship to the Bandwidth Delay Product (BDP) {#bdp}

The Bandwidth Delay Product (BDP), i.e. the product of the connection's RTT and the available bandwidth, is related to how much data can be in flight at any given time: If the receiver immediately acknowledges received data, it takes 1 RTT for the acknowledgment to arrive at the sender.

For example, on a connection with an available bandwidth of 1 Gbit/s and an RTT of 50ms, the BDP would be 6.25 MB.

If the receiver's flow control window is smaller than the BDP, the receiver won't be able to send any more data before receiving additional flow control credit, making it impossible to fully utilize the available bandwidth. quic-go therefore 

### Configuring Limits

Flow control limits are configured on a per-connection basis using the `quic.Config`.

```go
quic.Config{
  InitialStreamReceiveWindow: 1<<20, // 1 MB
  MaxStreamReceiveWindow: 6<<20, // 6 MB
  InitialConnectionReceiveWindow: 2<<20, // 2 MB
  MaxConnectionReceiveWindow: 12<<20, // 12 MB
}
```

The initial limits (`InitialStreamReceiveWindow` and `InitialConnectionReceiveWindow`) are advertised to the peer during the QUIC handshake, and apply to every new stream opened by the peer. The protocol doesn't provide a way to change these limits after the completion of the handshake. 

The maximum limits (`MaxStreamReceiveWindow` and `MaxConnectionReceiveWindow`) are the maximum sizes that the [auto-tuning algorithm](#auto-tuning) increases the limits to for a well-connected peer that is making of these limits.

The QUIC protocol allows specifying different limits for unidirectional, incoming bidirectional and outgoing bidirectional streams, quic-go currently doesn't expose configuration flags for that. The configuration flags provided apply to both streams types.

{{< callout type="warning" >}}
  While this API allows setting the connection limit to a value lower than the stream limit, there are no situation where this would makes sense.
{{< /callout >}}


### Auto-Tuning of the Receive Window {#auto-tuning}

When a stream -- or the connection in total, in case the data is distributed across multiple streams -- consumes the entire flow control (or close to that value) over any RTT, this is a sign that the flow control window might too small to allow full utilization of the available BDP.

In that case, the auto-tuning logic doubles the receive window. The flow control window is doubled until either the peer doesn't utilize the entire window within one RTT, or until the configured maximum value is reached.

This means that a suitable stream window size is usually reached within just a few network roundtrips.


## Limiting the Number of Streams {#stream-num}

A QUIC endpoint also imposes limits on the number of streams that the peer is allowed to open. The mechanism is described in [Section 4.6 of RFC 9000](https://datatracker.ietf.org/doc/html/rfc9000#section-4.6).

```go
quic.Config{
  MaxIncomingStreams: 100, // bidirectional streams
  MaxIncomingUniStreams: 100, // unidirectional streams
}
```

The QUIC protocols allow adjusting this number during the lifetime of the connection, similar to how it is possible to [adjust the receive window](#auto-tuning). Currently, quic-go doesn't expose an API for that.

These configuration flags determine the number of concurrent streams and not the total number of streams over the lifetime of a QUIC connection. Once a stream is closed and / or reset (in both directions, in the case of bidirectional streams), and all frames have been delivered to the peer, the peer is allowed to open a new stream.

{{< callout type="warning" >}}
  The `MaxIncomingStreams` and `MaxIncomingUniStreams` configuration flags only impose a limit on how many streams the peer can open. They do not limit how many streams the endpoint itself can open.
{{< /callout >}}


## 📝 Future Work

* queue stream-related frames with their respective stream: [#4271](https://github.com/quic-go/quic-go/issues/4271)
