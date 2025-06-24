---
title: Prometheus Metrics
toc: true
weight: 91
---

quic-go can expose metrics via Prometheus, providing a comprehensive overview of its operation. By leveraging the `Tracer` and `ConnectionTracer` structs, quic-go captures various events. These are the same structs used for [qlog event logging]({{< relref "qlog.md" >}}).

## Enabling Metrics Collection

In your application, expose a Grafana endpoint on `http://localhost:5001/prometheus`:
```go
import "github.com/prometheus/client_golang/prometheus/promhttp"

go func() {
    http.Handle("/prometheus", promhttp.Handler())
    log.Fatal(http.ListenAndServe("localhost:5001", nil))
}()
```

Event that don't belong to any QUIC connection, such as the sending of Version Negotiation packets, are captured on the `Transport.Tracer`:

```go
quic.Transport{
	Tracer: metrics.NewTracer(),
}
```

Events belonging to a QUIC connection, such as the reason a connection was closed, are captured on the `ConnectionTracer` returned from `Config.Tracer`.

```go
quic.Config{
	Tracer: metrics.DefaultConnectionTracer,
}
```


## 📝 Future Work

* Define more metrics: [#4554](https://github.com/quic-go/quic-go/issues/4554)
