---
title: Congestion Control
toc: true
weight: 10
---

A congestion controller aims to regulate network traffic to prevent overloading the network, ensuring efficient data transmission while minimizing packet loss and delays. QUIC implementations have the flexibility to explore innovative congestion control algorithms. Currently, quic-go implements the congestion control algorithm specified in [Section 7 of RFC 9002](https://datatracker.ietf.org/doc/html/rfc9002#section-7).


## 📝 Future Work

* Implement L4S / [Prague](https://datatracker.ietf.org/doc/draft-briscoe-iccrg-prague-congestion-control/): [#4002](https://github.com/quic-go/quic-go/issues/4002)
* Implement [Careful Resumption of Congestion Control State](https://datatracker.ietf.org/doc/draft-ietf-tsvwg-careful-resume/): [#4159](https://github.com/quic-go/quic-go/issues/4159)
* Pluggable Congestion Control: [#776](https://github.com/quic-go/quic-go/issues/776)
