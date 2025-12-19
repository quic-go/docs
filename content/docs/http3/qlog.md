---
title: Event Logging using qlog
toc: true
weight: 90
---

quic-go logs HTTP/3 events defined in [draft-ietf-quic-qlog-http3-events](https://datatracker.ietf.org/doc/draft-ietf-quic-qlog-http3-events/), providing detailed insights into HTTP/3 frame processing and datagram handling. This complements the QUIC-layer events to give a complete picture of HTTP/3 connections.

qlog files can be processed by a number of 3rd-party tools. [qvis](https://qvis.quictools.info/) has proven very useful for debugging all kinds of HTTP/3 and QUIC connection failures.

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

## Using with HTTP/3 Server

To enable qlogging for an HTTP/3 server:

```go
server := http3.Server{
	Handler:    mux,
	Addr:       "0.0.0.0:443",
	TLSConfig:  http3.ConfigureTLSConfig(&tls.Config{}),
	QUICConfig: &quic.Config{
		Tracer: h3qlog.DefaultConnectionTracer,
	},
}
err := server.ListenAndServe()
```

## Using with HTTP/3 Client

To enable qlogging for an HTTP/3 client:

```go
tr := &http3.Transport{
	TLSClientConfig: &tls.Config{
		NextProtos: []string{http3.NextProtoH3},
	},
	QUICConfig: &quic.Config{
		Tracer: h3qlog.DefaultConnectionTracer,
	},
}
defer tr.Close()
client := &http.Client{
	Transport: tr,
}
```

## Custom Tracer

For more sophisticated use cases, applications can implement a custom tracer callback. When doing so, make sure to include the HTTP/3 event schema (`h3qlog.EventSchema`) in addition to the QUIC event schema (`qlog.EventSchema`):

```go
import (
	"context"
	"fmt"
	"os"

	"github.com/quic-go/quic-go"
	"github.com/quic-go/quic-go/qlog"
	h3qlog "github.com/quic-go/quic-go/http3/qlog"
	"github.com/quic-go/quic-go/qlogwriter"
)

quic.Config{
  Tracer: func(ctx context.Context, isClient bool, id quic.ConnectionID) qlogwriter.Trace {
    f, err := os.Create(fmt.Sprintf("connection_%x.sqlog", id))
    // ... error handling
    return qlogwriter.NewConnectionFileSeq(
      f,
      isClient,
      id,
      []string{qlog.EventSchema, h3qlog.EventSchema},
    )
  }
}
```

## HTTP/3 Events

The following HTTP/3 events are logged:

- **`http3:frame_created`**: Logged when an HTTP/3 frame is created for transmission
- **`http3:frame_parsed`**: Logged when an HTTP/3 frame is successfully parsed from the network
- **`http3:datagram_created`**: Logged when an HTTP/3 datagram is created for transmission
- **`http3:datagram_parsed`**: Logged when an HTTP/3 datagram is successfully parsed

These events include details about the frame or datagram type and content. For example, HEADERS frames include the actual HTTP header fields, and SETTINGS frames include the negotiated parameters.

## Event Schema

HTTP/3 events use the schema identifier `urn:ietf:params:qlog:events:http3-12`, which follows the format defined in [draft-ietf-quic-qlog-http3-events](https://datatracker.ietf.org/doc/draft-ietf-quic-qlog-http3-events/).

Like QUIC events, HTTP/3 events are logged using the streaming JSON Text Sequences format (JSON-SEQ), as defined in [draft-ietf-quic-qlog-main-schema](https://www.ietf.org/archive/id/draft-ietf-quic-qlog-main-schema-09.html#section-11.2).
