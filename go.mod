module github.com/quic-go/docs

go 1.22.0

// Using the fork is only needed until the PR adding support for Umami is merged:
// https://github.com/imfing/hextra/pull/328
replace github.com/imfing/hextra => github.com/marten-seemann/hextra v0.0.0-20240321085151-430a25fbf9d1

require github.com/imfing/hextra v0.7.3 // indirect
