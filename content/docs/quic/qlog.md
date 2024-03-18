---
title: Event Logging using qlog
toc: true
weight: 99
---

quic-go logs a wide range of events defined in [draft-ietf-quic-qlog-quic-events](https://datatracker.ietf.org/doc/draft-ietf-quic-qlog-quic-events/), providing comprehensive insights in the internals of a QUIC connection. 

qlog files can be processed by a number of 3rd-party tools. [qviz](https://qvis.quictools.info/) has proven very useful for debugging all kinds of QUIC connection failures.

## Events associated with a Connection

qlog can be activated by setting the `Tracer` callback on the `Config`. It is called as soon as quic-go decides to start the QUIC handshake for a new connection.
`qlog.DefaultTracer` provides a tracer implementation which writes qlog files to a directory specified by the `QLOGDIR` environment variable, if set.
The default qlog tracer can be used like this:
```go
quic.Config{
  Tracer: qlog.DefaultTracer,
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

## 📝 Future Work

* qlog support for HTTP/3: [#4124](https://github.com/quic-go/quic-go/issues/4124)
* move to a different JSON serializer: [#3373](https://github.com/quic-go/quic-go/issues/3373)
