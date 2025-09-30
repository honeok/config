# certificate

## 安装

```shell
curl -Ls https://get.acme.sh | bash -s email=nginx@gmail.com
```

## 申请证书

- 使用letsencrypt证书，添加参数 `--server letsencrypt`

```shell
~/.acme.sh/acme.sh --issue --dns dns_cf -d honeok.com -d '*.honeok.com'
```

## 部署

```shell
~/.acme.sh/acme.sh --install-cert -d honeok.com \
    --fullchain-file /data/docker_data/nginx/certs/honeok.com_cert.pem \
    --key-file /data/docker_data/nginx/certs/honeok.com_key.pem \
    --reloadcmd "docker exec nginx nginx -s reload"
```

## 伪装证书

**Debian**

```shell
openssl genpkey -algorithm Ed25519 -out /data/docker_data/nginx/certs/default_server.key

openssl req -x509 \
    -key /data/docker_data/nginx/certs/default_server.key \
    -out /data/docker_data/nginx/certs/default_server.crt \
    -days 5475 \
    -subj "/C=US/ST=State/L=City/O=Organization/OU=Organizational Unit/CN=Common Name"
```

```shell
openssl rand -out "/data/docker_data/nginx/certs/ticket12.key" 48
openssl rand -out "/data/docker_data/nginx/certs/ticket13.key" 80
```
