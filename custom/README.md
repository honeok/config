# custom

## .bashrc

Description: This file is used to enhance the default .bashrc, add custom parameters.

```shell
cp ~/.bashrc{,.bak} && curl -Ls https://github.com/honeok/config/raw/master/custom/.bashrc -o ~/.bashrc
. ~/.bashrc
```

## .vimrc

Description: The vim script configuration is used to set a custom vim editor configuration.

```shell
curl -Ls https://github.com/honeok/config/raw/master/custom/.vimrc -o ~/.vimrc
```

## 99-honeok.sh

Description: This script is used custom MOTD showing hostname ip address disk usage and system uptime.

```shell
curl -Ls https://github.com/honeok/config/raw/master/custom/99-honeok.sh -o /etc/profile.d/99-honeok.sh
chmod +x /etc/profile.d/99-honeok.sh
```