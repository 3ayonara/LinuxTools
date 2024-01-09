## Opt Out of Data Collection

### Nginx
Blocking UA for Censys
```nginx
if ($http_user_agent ~* "^(?=.*censys)") {
    return 444;
}
```

### Caddy
```nginx
yourdomain.com {
    ...
    rewrite {
        r "^(?=.*censys)" 444
    }
}
```

### iptables
```
iptables -A INPUT -m string --algo bm --string "AS398722" -j DROP
iptables -A INPUT -m string --algo bm --string "AS398705" -j DROP
iptables -A INPUT -m string --algo bm --string "AS398324" -j DROP
```
## Consultation :

> Latest Official Documentation : https://support.censys.io/hc/en-us/articles/360043177092-from-faq

> HE : https://bgp.he.net/search?search%5Bsearch%5D=Censys&commit=Search