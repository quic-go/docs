---
title: WebTransport
toc: true
weight: 3
---

WebTransport is a novel [browser API](https://www.w3.org/TR/webtransport/) that enables browsers to establish stream-multiplexed connections to a server. It is layered atop QUIC and HTTP/3.

Conceptually, WebTransport can be compared to WebSocket but utilizes QUIC instead of TCP, providing benefits such as stream multiplexing and support for datagrams—features that enhance performance and efficiency for real-time communication. Despite these conceptual similarities, WebTransport and WebSocket differ significantly in their underlying protocols.

## Key Advantages and Use Cases

WebTransport leverages QUIC to improve connection reliability and efficiency, especially beneficial for applications requiring rapid and stable communication, such as online gaming and live video streaming.

A distinctive feature of WebTransport is [`serverCertificateHashes`](https://www.w3.org/TR/webtransport/#dom-webtransportoptions-servercertificatehashes), which makes it possible to use certificates not signed by a Certificate Authority (CA).

## Specification and Implementation Status

The WebTransport specification is still evolving, as the protocol is under active development in the [IETF WebTransport Working Group](https://datatracker.ietf.org/wg/webtrans/about/).

[webtransport-go](https://github.com/quic-go/webtransport-go) is the WebTransport implementation based on quic-go. It implements [draft version 16](https://www.ietf.org/archive/id/draft-ietf-webtrans-http3-16.html) of WebTransport over HTTP/3. It does not implement [WebTransport over HTTP/2](https://datatracker.ietf.org/doc/draft-ietf-webtrans-http2/).

{{< callout type="warning" >}}
  Browsers and webtransport-go might update to newer draft versions at different times.

  There is no guarantee that browsers will update in a backwards-compatible way, or that webtransport-go will support multiple draft versions at the same time. Support for WebTransport therefore might break for a transition period, until both browsers and servers have been updated to the new version.
{{< /callout >}}
