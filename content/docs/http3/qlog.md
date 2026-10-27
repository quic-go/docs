---
title: Event Logging using qlog
toc: true
weight: 90
---

quic-go logs HTTP/3 events defined in [draft-ietf-quic-qlog-h3-events](https://datatracker.ietf.org/doc/draft-ietf-quic-qlog-h3-events/), providing detailed insights into HTTP/3 frame processing and datagram handling. This complements the QUIC-layer events to give a complete picture of HTTP/3 connections.

## Enabling qlog for HTTP/3

HTTP/3 qlogging is enabled by setting the `Tracer` callback on the `quic.Config`, just like for QUIC connections. However, to log HTTP/3 events in addition to QUIC events, the tracer needs to support the HTTP/3 event schema.

The `http3/qlog` package provides `DefaultConnectionTracer`, which automatically includes both QUIC and HTTP/3 event schemas:

```go
import (
	"github.com/quic-go/quic-go"
	h3qlog "github.com/quic-go/quic-go/http3/qlog"
)

quic.Config{
  Tracer: h3qlog.DefaultConnectionTracer,
}
```

This tracer writes qlog files to a directory specified by the `QLOGDIR` environment variable, if set. Each connection will produce a separate qlog file containing both QUIC and HTTP/3 events.

As described in the [qlog documentation]({{< relref "../quic/qlog.md" >}}), applications can implement the `quic.Config.Tracer` callback to add custom logic to the qlog tracing.

## Redacting Field Values

By default, qlog logs HTTP/3 `HEADERS` frames, including all header and trailer field values. Applications can redact sensitive values by wrapping a connection tracer with `h3qlog.RedactHeaders`:

```go
tracer := h3qlog.RedactHeaders(
  h3qlog.DefaultConnectionTracer,
  func(name, value string) string {
    switch name {
    case "Authorization", "Cookie", "Set-Cookie":
      return "***"
    default:
      return value
    }
  },
)
```

The callback receives canonical field names (e.g. `Authorization`) for sent and received header and trailer fields. Pseudo-header names, such as `:path`, are passed unchanged.
