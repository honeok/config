## go.sh

Description: This script is used to install or update to the latest go version.

```shell
bash <(curl -sL https://github.com/honeok/config/raw/master/script/go.sh)
```

## jq.sh

Description: This script is used to install the jq command through a binary file, which is more lightweight.

```shell
bash <(curl -sL https://github.com/honeok/config/raw/master/script/jq.sh)
```

## iplocation.sh

Description: This script is used to query the ip ownership of mainland china from the general ip query interface.

Usage: `$1` is empty to query the server login user ip, and the parameter is the query parameter ip, which is only available in mainland `china`.

```shell
bash <(curl -sL https://github.com/honeok/config/raw/master/script/iplocation.sh) 123.123.123.124
```