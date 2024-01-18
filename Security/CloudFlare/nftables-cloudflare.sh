#!/bin/bash

if [ ! -d "/etc/nftables" ]; then
    mkdir /etc/nftables
fi

curl -s https://www.cloudflare.com/ips-v4 | tee /etc/nftables/cloudflare-ips-v4.txt
curl -s https://www.cloudflare.com/ips-v6 | tee /etc/nftables/cloudflare-ips-v6.txt

cp /etc/nftables.conf /etc/nftables.conf.bak

cat <<EOF > /etc/nftables.conf
table inet filter {
     set cloudflare-ipv4 {
          type ipv4_addr
          flags interval
          elements = { file "/etc/nftables/cloudflare-ips-v4.txt" }
     }
     set cloudflare-ipv6 {
          type ipv6_addr
          flags interval
          elements = { file "/etc/nftables/cloudflare-ips-v6.txt" }
     }

    chain input {
        type filter hook input priority 0;
        ip saddr @cloudflare-ipv4 tcp dport { 80,443 } accept
        ip6 saddr @cloudflare-ipv6 tcp dport { 80,443 } accept
        tcp dport 22 accept
        ct state related,established accept
        counter reject
    }
}
EOF

if [ -f "/etc/nftables.conf" ]; then
    nft -f /etc/nftables.conf
fi

exit 0