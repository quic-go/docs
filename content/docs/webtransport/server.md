---
title: Running a Server
toc: true
weight: 1
---

When a client establishes a new WebTransport session it:
1. First establishes an HTTP/3 connection to the server.
2. It sends an HTTP request (using the Extended CONNECT protocol) to the server, requesting to establish a WebTransport session.

## Accepting a WebTransport Session

To start a WebTransport server, it is necessary to:
1. Set up an HTTP/3 server.
2. Set up an HTTP handler for the WebTransport Extended CONNECT request.

The `webtransport.Server` wraps an `http3.Server`. For more details on how to set up and configure an HTTP/3 server, see [Serving HTTP/3]({{< relref "../http3/server.md" >}}).

Assume a server is running on `example.com`. This code starts an HTTP/3 server on (UDP) port 443. The server can handle regular HTTP/3 requests to `https://example.com`.

To accept the Extended CONNECT request, the application needs to define an HTTP handler. In this example, we want to accept WebTransport sessions at `https://example.com/webtransport`. It is possible to reject an upgrade request by sending a non-2xx status code. Inside the handler, calling `webtransport.Server.Upgrade` accepts the [WebTransport session]({{< relref "session.md" >}}), and it returns a `webtransport.Session`.

```go
s := webtransport.Server{
    H3: http3.Server{
      Addr: ":443",
      TLSConfig: &tls.Config{}, // use your tls.Config here
    },
}

// Create a new HTTP endpoint /webtransport.
http.HandleFunc("/webtransport", func(w http.ResponseWriter, r *http.Request) {
    sess, err := s.Upgrade(w, r)
    if err != nil {
        log.Printf("upgrading failed: %s", err)
        w.WriteHeader(500)
        return
    }
    // Handle the session. Here goes the application logic. 
})

s.ListenAndServeTLS(<certFile>, <keyFile>)
```

## Application Protocol Negotiation

A server can select a WebTransport application protocol offered by the client by setting `ApplicationProtocols`. This is the WebTransport-specific negotiation described in the [Application Protocol Negotiation section](https://datatracker.ietf.org/doc/html/draft-ietf-webtrans-http3#section-3.3) of the WebTransport over HTTP/3 draft, not TLS ALPN.

```go
s := webtransport.Server{
    H3: &http3.Server{
        Addr:      ":443",
        TLSConfig: &tls.Config{}, // use your tls.Config here
    },
    ApplicationProtocols: []string{"foo", "bar"},
}
```

`Upgrade` selects the first client-offered protocol that also appears in `ApplicationProtocols`. The selected protocol is available on the returned session:

```go
http.HandleFunc("/webtransport", func(w http.ResponseWriter, r *http.Request) {
    sess, err := s.Upgrade(w, r)
    if err != nil {
        log.Printf("upgrading failed: %s", err)
        w.WriteHeader(500)
        return
    }

    switch sess.SessionState().ApplicationProtocol {
    case "foo":
        // handle foo
    case "bar":
        // handle bar
    default:
        // No application protocol was negotiated.
    }
})
```

If there is no overlap between the client's offered protocols and the server's `ApplicationProtocols`, `Upgrade` accepts the session without selecting a protocol and `ApplicationProtocol` is empty.

## Origin Validation

By default, the `Upgrade` function checks that the client's request origin matches the host of the server. This prevents cross-site request forgery (CSRF) attacks, where an attacker could use a malicious web page to establish a WebTransport connection to a vulnerable application, with the application processing the connection as if it were part of the victim user's session.

Applications can change this default behavior by setting the `webtransport.Server.CheckOrigin` callback:

```go
s := webtransport.Server{
    H3: http3.Server{Addr: ":443"},
    CheckOrigin: func(r *http.Request) bool {
      // custom validation logic
    },
}
```


## 📝 Future Work

* Properly check Validity of the client's SETTINGS: [#106](https://github.com/quic-go/webtransport-go/issues/106)
