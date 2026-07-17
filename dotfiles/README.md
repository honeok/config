<div align="center">
  <img src="https://fastly.jsdelivr.net/gh/jglovier/dotfiles-logo@main/dotfiles-logo.png" alt="Logo" width="450" />
</div>

## 99-honeok.sh

A lightweight custom MOTD script that displays Fastfetch output, hostname, public IP addresses, disk usage, system uptime, and the current login time.

```shell
curl -fsSL https://github.com/honeok/config/raw/master/dotfiles/99-honeok.sh -o /etc/profile.d/99-honeok.sh
chmod +x /etc/profile.d/99-honeok.sh
```
