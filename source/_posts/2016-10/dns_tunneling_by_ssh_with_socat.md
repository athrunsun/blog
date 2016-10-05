---
title: "(Reproduce) DNS (UDP) tunneling by SSH with socat"
date: 2016-10-05 22:34:55
categories: DNS
tags:
- DNS
- SSH
---
[Original Post](http://gihnius.net/2014/08/60-ssh-dns-tunnel-by-socat/)

# Intro

In China, many "ISP" sucks. Their DNS servers often return incorrect ip address results,  is known as DNS poisoning! DNS poisoning is a common and simple way to stop people reaching correct web pages.

Here is a solution to get the correct DNS queries results.

# Dependent tools

* Server
  * A VPS server that can access famous public DNS servers correctly, eg. `8.8.8.8` (google dns) or `208.67.222.222` (opendns).
  * SSH server running on that VPS. (Please google: how to setup ssh server)
  * socat (Socket Cat). (Please google: how to setup or install socat)
  * dnsmasq (Optional, for caching).
* Local
  * SSH client
  * socat (Socket Cat)
  * dnsmasq (Optional, for caching).

ssh, socat, dnsmasq are open source softwares which can be found and installed easily.

# Samples and Steps

* Server
  * Setup a DNS caching server using dnsmasq. (Optional)
    * install dnsmasq
    * configure example using google dns and opendns servers. please check out: Setup a DNS cache server using dnsmasq
    * start dnsmasq
  * If no local dns server, just use a public dns server instead, eg. `8.8.8.8:53`
  * Forwarding **UDP** to **TCP** by socat (listen on port: `15353`)
    * install socat
    * start socat:
      * if use a public dns server, eg. `8.8.8.8:53`
        `socat tcp4-listen:15353,reuseaddr,fork,bind=127.0.0.1 UDP:8.8.8.8:53`
      * if use local dns caching server: `127.0.0.1:5353`
        `socat tcp4-listen:15353,reuseaddr,fork,bind=127.0.0.1 UDP:127.0.0.1:53`
  * You can check the forwarding dns server using command line:
    `dig +tcp google.com @127.0.0.1 -p 15353`
* Local
  * Setup SSH tunnel 
    `ssh -N -L 15353:localhost:15353 username@vps.ip`
  * Forwarding TCP to UDP by socat
    * if no local dns caching server, you can forward to port `53`
      `socat udp-recvfrom:53,reuseaddr,bind=127.0.0.1,fork tcp:127.0.0.1:15353`
    * of cause can forward to any port that can be used.
      `socat udp-recvfrom:15353,reuseaddr,bind=127.0.0.1,fork tcp:127.0.0.1:15353`
  * Setup local dns caching server (Optional but recommend). See the server instruction above.

OK!

Oh not yet!

ssh (tunnel) is not always working well! WTF!
