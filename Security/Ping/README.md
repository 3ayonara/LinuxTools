## Disable PING
```
echo 1 > /proc/sys/net/ipv4/icmp_echo_ignore_all
```
## Open PING
```
echo 0 > /proc/sys/net/ipv4/icmp_echo_ignore_all
```