<div align="center">
  <img src="https://cdn.jsdelivr.net/gh/jglovier/dotfiles-logo@838ebffb69b8482fe218a0f6c4eb05b19d235119/dotfiles-logo.svg" alt="Logo" width="450" />
</div>

## 99-honeok.sh

A lightweight custom MOTD script that displays Fastfetch output, hostname, public IP addresses, disk usage, system uptime, and the current login time.

```shell
curl -fsSL https://github.com/honeok/config/raw/main/dotfiles/99-honeok.sh -o /etc/profile.d/99-honeok.sh
chmod +x /etc/profile.d/99-honeok.sh
```
