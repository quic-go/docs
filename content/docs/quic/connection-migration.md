---
title: Connection Migration
toc: true
weight: 50
---

Whereas TCP identifies connection by their 4-tuple (i.e. the combination of the client's and server's IP address and port), QUIC uses connection IDs to demultiplex connections. This allows QUIC connections to migrate between paths.


This can be useful when a mobile phone moves away from a WiFi networks, and wishes to use the cellular connection instead. Connection migration is completely transparent to the application, as the entire connection, including all streams, is migrated to the new path.

{{< callout type="warning" >}}
  Note that this is not equivalent to multipath support. Using connection migration as defined in RFC 9000, only a single path can be used to send application at a time.

  See [Multipath]({{< relref path="multipath.md" >}}) for the QUIC Multipath extension.
{{< /callout >}}

## 📝 Future Work

quic-go currently doesn't implement connection migration at this point.

* Tracking Issue: [#234](https://github.com/quic-go/quic-go/issues/234)
* API Proposal: [#3990](https://github.com/quic-go/quic-go/issues/3990)
