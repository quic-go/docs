---
title: Event Logging using qlog
toc: true
weight: 90
---

quic-go logs a wide range of events defined in [draft-ietf-quic-qlog-quic-events](https://datatracker.ietf.org/doc/draft-ietf-quic-qlog-quic-events/), providing comprehensive insights in the internals of a QUIC connection. 

qlog files can be processed by a number of 3rd-party tools. [qvis](https://qvis.quictools.info/) has proven very useful for debugging all kinds of QUIC connection failures.

## Events associated with a Connection

qlog can be activated by setting the `Tracer` callback on the `Config`. It is called as soon as quic-go decides to start the QUIC handshake for a new connection.
`qlog.DefaultConnectionTracer` provides a connection tracer implementation which writes qlog files to a directory specified by the `QLOGDIR` environment variable, if set.
The default qlog tracer can be used like this:
```go
quic.Config{
  Tracer: qlog.DefaultConnectionTracer,
}
```

For more sophisticated use cases, applications can implement the callback:
```go
quic.Config{
  Tracer: func(
    ctx context.Context, 
    p logging.Perspective, 
    connID quic.ConnectionID,
  ) *logging.ConnectionTracer {
    // application-defined logic
  }
}
```

The `context.Context` passed to this callback is never closed, but it carries a `quic.ConnectionTracingKey` value. This value is also set on the context returned from `Connection.Context`.

It is valid to return `nil` for the `*logging.ConnectionTracer` from this callback. In this case, qlogging will be disabled for this connection.

## Events not associated with a Connection

When listening for QUIC packets on a UDP socket, there are a couple of events that can happen before an incoming packet can be associated with a QUIC connection. For example, the QUIC packet header might be invalid, forcing us to drop the packet. Or the server might be overloaded and reject a new connection attempt.

qlogging for these events can be enabled by configuring a `Tracer` on the [`Transport`]({{< relref path="transport.md" >}}):
```go
f, err := os.Create("events.qlog")
// ... error handling
quic.Transport{
  Tracer: qlog.NewTracer(f),
}
```

## 📝 Future Work

* qlog support for HTTP/3: [#4124](https://github.com/quic-go/quic-go/issues/4124)
* move to a different JSON serializer: [#3373](https://github.com/quic-go/quic-go/issues/3373)
