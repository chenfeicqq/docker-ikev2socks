# IKEv2 转 SOCKS5

原理：
1. 使用 strongswan 建立 IKEv2 连接；
2. 使用 gost 启动 SOCKS 服务，代理请求；

## 创建容器

``` shell
docker run -d \
--cap-add=NET_ADMIN \
-p 1080:1080 \
-v <your ipsec.conf>:/etc/ipsec.conf \
-v <your ipsec.secrets>:/etc/ipsec.secrets \
--name=ikev2socks \
chenfeicqq/ikev2socks:latest
```

## 配置文件

+ ipsec.conf

``` yaml
config setup
    charondebug="ike 2, knl 2, cfg 2, net 2, esp 2, dmn 2,  mgr 2"

conn vpn
    left=%config
    leftsourceip=%config
    leftauth=eap-gtc
    right=<remote server>
    rightsubnet=0.0.0.0/0
    rightid=<remote id>
    rightauth=pubkey
    eap_identity=<username>
    auto=add
```

+ ipsec.secrets

``` yaml
<username> : EAP <password>
```

配置项：
+ `<remote server>` 服务器地址
+ `<remote id>` 远程ID
+ `<username>` 用户名
+ `<password>` 密码