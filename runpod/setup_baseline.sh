# Setup tailscale
tailscaled --tun=userspace-networking --socks5-server=localhost:1055 >/tmp/ts.log 2>&1 &
tailscale up
export ALL_PROXY=socks5h://127.0.0.1:1055

# transfer repo from local
tar -C ~/ -czf - mapping-llm-censorship | ssh runpod-scp 'tar -xzf - -C ~'

# get pip to install & install dependencies
unset ALL_PROXY http_proxy https_proxy
pip install --upgrade pip
pip install -r requirements.txt # repo dependencies
export ALL_PROXY=socks5h://127.0.0.1:1055
export PIP_BREAK_SYSTEM_PACKAGES=1 # optional, in case of blinker issue
pip install -U --ignore-installed blinker

