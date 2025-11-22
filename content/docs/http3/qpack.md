---
title: QPACK Header Field Compression
toc: true
weight: 3
---

HTTP/3 utilizes QPACK ([RFC 9204](https://datatracker.ietf.org/doc/html/rfc9204)) for efficient HTTP header field compression. Our implementation, available at [quic-go/qpack](https://github.com/quic-go/qpack), provides a minimal implementation of the protocol. 

## Implementation Status

While the current implementation is a fully interoperable implementation of the QPACK protocol, it only uses the static compression table. The dynamic table would allow for more effective compression of frequently transmitted header fields. This can be particularly beneficial in scenarios where headers have considerable redundancy or in high-throughput environments.

If you think that your application would benefit from higher compression efficiency, or if you're interested in contributing improvements here, please let us know in [#2424](https://github.com/quic-go/quic-go/issues/2424).

## 📝 Future Work

* Add support for the QPACK dynamic table: [#2424](https://github.com/quic-go/quic-go/issues/2424) and [qpack#33](https://github.com/quic-go/qpack/issues/33)
