```shell
                         __      _ _ ___ _               
                        / _|__ _(_) |_  ) |__  __ _ _ _  
                       |  _/ _` | | |/ /| '_ \/ _` | ' \ 
                       |_| \__,_|_|_/___|_.__/\__,_|_||_|
```

## Fail2Ban: ban hosts that cause multiple authentication errors

Description: This script is used to install fail2ban based on docker and configure ssh interception jail rules.

```shell
curl -LOs https://github.com/honeok/config/raw/master/security/fail2ban/fail2ban.sh && chmod +x fail2ban.sh
./fail2ban.sh
```
or
```shell
curl -LOs https://gh-proxy.com/https://github.com/honeok/config/raw/master/security/fail2ban/fail2ban.sh && chmod +x fail2ban.sh
./fail2ban.sh
```