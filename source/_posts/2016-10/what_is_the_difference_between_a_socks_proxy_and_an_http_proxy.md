---
title: "(Reproduce) What is the difference between a SOCKS proxy and an HTTP proxy?"
date: 2016-10-05 22:43
categories: Proxy
tags:
- Proxy
- SOCKS
---
[Original Post](http://www.jguru.com/faq/view.jsp?EID=227532)

A SOCKS server is a **general purpose** proxy server that establishes a TCP connection to another server on behalf of a client, then routes all the traffic back and forth between the client and the server. It works for any kind of network protocol on any port. SOCKS Version 5 adds additional support for security and UDP.

The SOCKS server does not interpret the network traffic between client and server in any way, and is often used because clients are behind a firewall and are not permitted to establish TCP connections to servers outside the firewall unless they do it through the SOCKS server.

Most web browsers for example can be configured to talk to a web server via a SOCKS server. Because the client must first make a connection to the SOCKS server and tell it the host it wants to connect to, the client must be "SOCKS enabled."

On Windows, it is possible to "shim" the TCP stack so that all client software is SOCKS enabled. A free SOCKS shim is available from Hummingbird at http://www.hummingbird.com/products/nc/socks/index.html.

An HTTP proxy is similar, and may be used for the same purpose when clients are behind a firewall and are prevented from making outgoing TCP connections to servers outside the firewall.

However, unlike the SOCKS server, an HTTP proxy does understand and interpret the network traffic that passes between the client and downstream server, namely the HTTP protocol.

Because of this the HTTP proxy can **ONLY** be used to handle HTTP traffic, but it can be very smart about how it does it. In particular, it can recognize often repeated requests and cache the replies to improve performance.

Many ISPs use HTTP proxies regardless of how the browser is configured because they simply route all traffic on port 80 through the proxy server.
