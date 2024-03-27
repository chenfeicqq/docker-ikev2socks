#!/bin/bash

function up_ip_sec() {
    # 成功标识
    local success=0
    # 遍历所有 conn
    while IFS= read -r line; do

        # conn 名称
        local conn_name=$(echo "$line" | awk '{print $2}')

        echo "IPSec 开始连接 $conn_name（超时时间 $TIMEOUT 秒）"

        # 连接 vpn
        ipsec up "$conn_name" &

        # 计时器
        local timer=0
        # 检测 IPSec 连接状态
        while true; do
            # 使用 status 命令检查连接状态
            if ipsec status | grep -q "ESTABLISHED"; then
                echo "IPSec 连接 $conn_name 成功！"
                success=1
                break
            fi
            echo "IPSec 连接 $conn_name 中，$timer 秒"
            # 如果超时，则退出循环
            if [ $timer -ge $TIMEOUT ]; then
                echo "IPSec 连接 $conn_name 超时！"
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
    # 返回结果
    return $success
}

function health_check() {
    # 循环检查状态
    while true; do
        if ipsec status | grep -q "ESTABLISHED"; then
            echo "IPSec 连接正常！"
            # 存在连接，等待10秒钟再进行下一次检测
            sleep 10
        else
            echo "IPSec 连接丢失！"
            # 重新连接
            up_ip_sec
        fi
    done
}


# 拷贝系统证书
cp -r /etc/ssl/certs/* /etc/ipsec.d/cacerts

# 后台启动 IPSec。--nofork 不开启新进程，实现日志打印到当前进程
ipsec start --nofork &

# 等待 10 秒，等 IPSec 启动成功
sleep 10

# 连接 IPSec
up_ip_sec
# 成功标识
success=$?

if [ $success -eq 0 ]; then
    # 连接失败
    exit 1
fi

# 连接成功，启动健康检查
health_check &

echo "启动 Gost socks5"
# 启动 gost socks5
exec gost -L socks5://:1080