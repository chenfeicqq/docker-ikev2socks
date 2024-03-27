#!/bin/bash

# 拷贝系统证书
cp -r /etc/ssl/certs/* /etc/ipsec.d/cacerts

# 后台启动 ipsec
# --nofork 不开启新进程，实现日志打印到当前进程
ipsec start --nofork &

# 等待 10 秒，等 ipsec 启动成功
sleep 10

# 成功标识
success=0
# 遍历所有 conn
while IFS= read -r line; do

    # conn 名称
    conn_name=$(echo "$line" | awk '{print $2}')

    echo "IPsec 开始连接 $conn_name（超时时间 $TIMEOUT 秒）"

    # 连接 vpn
    ipsec up "$conn_name" &

    # 计时器
    timer=0
    # 检测 IPsec 连接状态
    while true; do
        # 使用 ipsec status 命令检查连接状态
        if ipsec status | grep -q "ESTABLISHED"; then
            echo "IPsec 连接 $conn_name 成功！"
            success=1
            break
        fi
        echo "IPsec 连接 $conn_name 中，$timer 秒"
        # 如果超时，则退出循环
        if [ $timer -ge $TIMEOUT ]; then
            echo "IPsec 连接 $conn_name 超时！"
            ipsec down "$conn_name"
            break
        fi
        # 等待一秒钟再进行下一次检测
        sleep 1
        # 增加计时器
        ((timer++))
    done

    # 连接成功结束循环
    if [ $success -eq 1 ]; then
        break
    fi
done < <(grep '^conn' "/etc/ipsec.conf")

# 连接失败
if [ "$success" -eq 0]; then
    exit 1
fi

echo "启动 Gost socks5"
# 启动 gost socks5
exec gost -L=socks5://:1080
