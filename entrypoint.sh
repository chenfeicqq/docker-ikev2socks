#!/bin/bash

# 拷贝系统证书
cp -r /etc/ssl/certs/* /etc/ipsec.d/cacerts

# 后台启动 ipsec
# --nofork 不开启新进程，实现日志打印到当前进程
ipsec start --nofork &

# 等待 5 秒，等 ipsec 启动成功
sleep 5

echo "IPsec 开始连接（超时时间 $TIMEOUT 秒）"

# 连接 vpn
ipsec up vpn &

# 计时器
TIMER=0
# 检测 IPsec 连接状态
while true; do
    # 使用 ipsec status 命令检查连接状态
    if ipsec status | grep -q "ESTABLISHED"; then
        echo "IPsec 连接成功！"
        break
    fi
    echo "IPsec 连接中，$TIMER 秒"
    # 如果超时，则退出循环
    if [ $TIMER -ge $TIMEOUT ]; then
        echo "IPsec 连接超时！"
        exit 1
    fi
    # 等待一秒钟再进行下一次检测
    sleep 1
    # 增加计时器
    ((TIMER++))
done

echo "启动 Gost socks5"
# 启动 gost socks5
exec gost -L=socks5://:1080
