---
title: WebTransport
toc: true
weight: 3
---

WebTransport is a novel [browser API](https://www.w3.org/TR/webtransport/) that enables browsers to establish stream-multiplexed connections to a server. It is layered atop QUIC and HTTP/3, offering a fallback mechanism on HTTP/2 for scenarios where QUIC might be blocked.

Conceptually, WebTransport can be compared to WebSocket but utilizes QUIC instead of TCP, providing benefits such as stream multiplexing and support for datagrams—features that enhance performance and efficiency for real-time communication. Despite these conceptual similarities, WebTransport and WebSocket differ significantly in their underlying protocols.

## Key Advantages and Use Cases

WebTransport leverages QUIC to improve connection reliability and efficiency, especially beneficial for applications requiring rapid and stable communication, such as online gaming and live video streaming.

A distinctive feature of WebTransport is [`serverCertificateHashes`](https://www.w3.org/TR/webtransport/#dom-webtransportoptions-servercertificatehashes), which makes it possible to use certificates not signed by a Certificate Authority (CA).

## Specification and Implementation Status

The WebTransport specification is still evolving, as the protocol is under active development in the [IETF WebTransport Working Group](https://datatracker.ietf.org/wg/webtrans/about/).

As of now, both Chrome and Firefox [support](https://caniuse.com/mdn-api_webtransport) WebTransport over HTTP/3 in [draft version 2](https://datatracker.ietf.org/doc/draft-ietf-webtrans-http3/02/). The [HTTP/2 fallback](https://datatracker.ietf.org/doc/draft-ietf-webtrans-http2/) is currently not implemented by either browser.

[webtransport-go](https://github.com/quic-go/webtransport-go) is the WebTransport implementation based on quic-go. It is compatible with both Chrome and Firefox at this point.

{{< callout type="warning" >}}
  At some point in the future, browsers will update to a more recent IETF draft version (or the final RFC version).

  There is no guarantee that browsers will update in a backwards-compatible way, or that webtransport-go will support multiple draft versions at the same time. Support for WebTransport therefore might break for a transition period, until both browsers and servers have been updated to the new version.
{{< /callout >}}
