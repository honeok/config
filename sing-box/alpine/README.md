# Sing-box for Alpine

## 准备工作

```shell
mkdir -p /etc/sing-box/{conf,bin}
mkdir -p /var/log/sing-box && touch /var/log/sing-box/access.log
```

## 启动

```shell
chmod +x /etc/init.d/sing-box
rc-update add sing-box default
rc-service sing-box start
```