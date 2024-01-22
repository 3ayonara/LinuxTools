#!/bin/bash

if [ ! -d "/etc/nftables" ]; then
     mkdir /etc/nftables
fi

curl -s https://www.cloudflare.com/ips-v4 | tee /etc/nftables/cloudflare-ips-v4.txt
curl -s https://www.cloudflare.com/ips-v6 | tee /etc/nftables/cloudflare-ips-v6.txt
curl -o /etc/nftables/censys-ips.txt https://support.censys.io/hc/en-us/article_attachments/20618695168532
grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(/[0-9]+)?$' /etc/nftables/censys-ips.txt >/etc/nftables/censys-ips-v4.txt
grep -E '^[0-9a-fA-F:]+(/[0-9]+)?$' /etc/nftables/censys-ips.txt >/etc/nftables/censys-ips-v6.txt

cp /etc/nftables.conf /etc/nftables.conf.bak

censys_ipv4=$(cat /etc/nftables/censys-ips-v4.txt | tr -s '\n' ',')
censys_ipv6=$(cat /etc/nftables/censys-ips-v6.txt | tr -s '\n' ',')
cloudflare_ipv4=$(cat /etc/nftables/cloudflare-ips-v4.txt | tr -s '\n' ',')
cloudflare_ipv6=$(cat /etc/nftables/cloudflare-ips-v6.txt | tr -s '\n' ',')

cat <<EOF >/etc/nftables.conf
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
     
     set censys-ipv4 {
          type ipv4_addr
          flags interval
          elements = { $censys_ipv4 }
     }
     set censys-ipv6 {
          type ipv6_addr
          flags interval
          elements = { $censys_ipv6 }
     }

    chain input {
        type filter hook input priority 0;
        ip saddr @cloudflare-ipv4 tcp dport { 80,443 } accept
        ip6 saddr @cloudflare-ipv6 tcp dport { 80,443 } accept
        ip saddr @censys-ipv4 drop
        ip6 saddr @censys-ipv6 drop
        tcp dport 22 accept
        ct state related,established accept
        counter reject
    }

    # 添加 IPv6 允许出站流量规则
    chain output {
        type filter hook output priority 0;
        ip6 daddr fe80::/10 accept
        ip6 daddr ::/0 accept
    }
}
EOF

if [ -f "/etc/nftables.conf" ]; then
     nft -f /etc/nftables.conf
fi

systemctl enable nftables.service
systemctl restart nftables.service

exit 0
