FROM archlinux:latest

# 设置清华大学的 Arch Linux 镜像源
RUN echo "Server = https://mirrors.tuna.tsinghua.edu.cn/archlinux/\$repo/os/\$arch" > /etc/pacman.d/mirrorlist

# 更新包数据库
RUN pacman -Syu --noconfirm

# 安装
RUN pacman -S --noconfirm strongswan gost

# 清理缓存，减小镜像体积
RUN pacman -Scc --noconfirm

ADD entrypoint.sh /entrypoint.sh

EXPOSE 1080
ENTRYPOINT ["/entrypoint.sh"]



