#!/usr/bin/bash

# Install & setup tailscale
curl -fsSL https://tailscale.com/install.sh | sh
tailscaled --tun=userspace-networking --socks5-server=localhost:1055 >/tmp/ts.log 2>&1 &
tailscale up
export ALL_PROXY=socks5://127.0.0.1:1055 # with socks5h normally but httpx doesnt accept it




