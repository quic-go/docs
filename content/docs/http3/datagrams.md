---
title: HTTP Datagrams
toc: true
weight: 10
---

[RFC 9297](https://datatracker.ietf.org/doc/rfc9297/) defines how QUIC datagrams (as defined in [RFC 9221](https://datatracker.ietf.org/doc/rfc9221/)) can be used in HTTP.

All HTTP Datagrams are associated with an HTTP request. Datagrams can only be sent with an HTTP request methods that explicitly supports them. For example, the GET and POST methods can't be used for HTTP Datagrams.

## On the Server Side

Since HTTP Datagram support is an HTTP/3 extension, it needs to be negotiated using the [HTTP/3 SETTINGS]({{< relref "server.md#settings" >}}) before it can be used. Since SETTINGS are sent in a unidirectional stream, it is not guaranteed that the SETTINGS are available as soon as the QUIC handshake completes.

For example, if a client sends a request immediately after the handshake completes and the QUIC packet containing the SETTINGS is lost, the SETTINGS will not be available until a retransmission is received.

To use HTTP datagrams, the server is required to check that support is actually enabled.

```go
http.HandleFunc("/datagrams", func(w http.ResponseWriter, r *http.Request) {
	conn := w.(http3.Hijacker).Connection()
	// wait for the client's SETTINGS
	select {
	case <-conn.ReceivedSettings():
	case <-time.After(10 * time.Second):
		// didn't receive SETTINGS within 10 seconds
		w.WriteHeader(http.StatusBadRequest)
		return
	}
	// check that HTTP Datagram support is enabled
	settings := conn.Settings()
	if !settings.EnableDatagrams {
		w.WriteHeader(http.StatusBadRequest)
		return
	}
	// HTTP datagrams are available
	w.WriteHeader(http.StatusOK)
	// ... handle the request ...
})
```

After HTTP datagram has been verified, it is possible to "take over" the stream by type-asserting the `http.ResponseWriter` to an `http3.HTTPStreamer` and calling the `HTTPStream` method. The returned `http3.Stream` has two methods, `SendDatagram` and `ReceiveDatagram`, to send and receive datagrams, respectively.

Once `HTTPStream` has been called, the stream behaves akin to a [QUIC Stream]({{< relref "../quic/streams.md" >}}) in terms of reads, writes and stream cancellations.

When writing to the `http.ResponseWriter`, the HTTP/3 layer applies framing using HTTP/3 DATA frames. By taking over the streams we gain access to the underlying QUIC stream: data passed to `Write` is written to the stream directly, and `Read` reads from the stream directly. This is a requirement for the Capsule protocol defined in [section 3 of RFC 9297](https://datatracker.ietf.org/doc/html/rfc9297#section-3).


Continuing the code sample from above:

```go
http.HandleFunc("/datagrams", func(w http.ResponseWriter, r *http.Request) {
	// ... check for HTTP datagram support, see above
	w.WriteHeader(http.StatusOK)

	str := w.(http3.HTTPStreamer).HTTPStream()

	// send an HTTP datagram
	err := str.SendDatagram([]byte("foobar"))
	// ... handle error ...

	// receive an HTTP datagram
	data, err := str.ReceiveDatagram(context.Background())
	// ... handle error ...

	// send data directly on the QUIC stream
	str.Write([]byte("message"))
	str.Close()
})
```

## On the Client Side

On the client side, the client needs to use an `http3.SingleDestinationRoundTripper`. It is not possible to use HTTP datagrams when using an `http3.RoundTripper`.

The `http3.SingleDestinationRoundTripper` manages a single QUIC connection to a remote server.

The client is required to check that the server enabled HTTP datagrams support by checking the SETTINGS:

```go
// ... dial a quic.Connection to the target server
// make sure to set the "h3" ALPN
rt := &http3.SingleDestinationRoundTripper{
	Connection:      qconn,
	EnableDatagrams: true,
}
conn := rt.Start()
// wait for the server's SETTINGS
select {
case <-conn.ReceivedSettings():
case <-conn.Context().Done():
	// connection closed
	return
}
settings := conn.Settings()
if !settings.EnableDatagrams {
	// no datagram support
	return
}
```

Since an HTTP/3 server can [send SETTINGS]({{< relref "server.md#settings" >}}) in 0.5-RTT data, the SETTINGS are usually available right after completion of the QUIC handshake (barring packet loss, or an unoptimized HTTP/3 server implementation).

```go
str, err := rt.OpenRequestStream(ctx)
// ... handle error ...

// send the HTTP request
err = str.SendRequestHeader(req)
// ... handle error ...
// It now takes (at least) 1 RTT until we receive the server's HTTP response.
// We can start sending HTTP datagrams now.
go func() {
	// send an HTTP datagram
	err := str.SendDatagram([]byte("foobar"))
	// ... handle error ...

	// receive an HTTP datagram
	data, err := str.ReceiveDatagram(context.Background())
	// ... handle error ...
}()

// read the server's HTTP response
rsp, err := str.ReadResponse()
// ... handle error ...
```

The `SingleDestinationRoundTripper` splits the sending of the HTTP request and the receiving of the HTTP response into two separate API calls (compare that to the standard library's `RoundTrip` function). The reason is that sending an HTTP request and receiving the HTTP response from the server takes (at least) one network roundtrip. RFC 9297 allows the sending of HTTP datagrams as soon as the request has been sent.
