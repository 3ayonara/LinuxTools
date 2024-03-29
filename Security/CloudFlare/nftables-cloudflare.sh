#!/bin/bash

if [ ! -d "/etc/nftables" ]; then
    mkdir /etc/nftables
fi

curl -s https://www.cloudflare.com/ips-v4 | tee /etc/nftables/cloudflare-ips-v4.txt
curl -s https://www.cloudflare.com/ips-v6 | tee /etc/nftables/cloudflare-ips-v6.txt

cp /etc/nftables.conf /etc/nftables.conf.bak

cloudflare_ipv4=$(cat /etc/nftables/cloudflare-ips-v4.txt | tr -s '\n' ',')
cloudflare_ipv6=$(cat /etc/nftables/cloudflare-ips-v6.txt | tr -s '\n' ',')

cat <<EOF >/etc/nftables.conf
#!/usr/sbin/nft -f

flush ruleset

table inet filter {
     set cloudflare-ipv4 {
          type ipv4_addr
          flags interval
          elements = { $cloudflare_ipv4 }
     }
     set cloudflare-ipv6 {
          type ipv6_addr
          flags interval
          elements = { $cloudflare_ipv6 }
     }

    chain input {
          type filter hook input priority 0;
          ip saddr @cloudflare-ipv4 tcp dport { 80,443 } accept
          ip6 saddr @cloudflare-ipv6 tcp dport { 80,443 } accept
          tcp dport 22 accept
          iifname lo accept

          icmp type echo-request counter drop
          icmpv6 type echo-request drop
          icmpv6 type { nd-neighbor-solicit,nd-neighbor-advert,nd-router-solicit,nd-router-advert } accept

          ct state related,established accept
          counter reject
    }
    
    chain forward {
          type filter hook forward priority filter;
    }

    chain output {
          type filter hook output priority filter;
    }
}
EOF

if [ -f "/etc/nftables.conf" ]; then
    nft -f /etc/nftables.conf
fi

systemctl enable nftables.service
systemctl restart nftables.service

exit 0
