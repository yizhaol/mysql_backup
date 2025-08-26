FROM alpine:latest

# 安装必要的软件
RUN apk update && \
    apk add --no-cache mysql-client bash tzdata && \
    rm -rf /var/cache/apk/*

# 创建备份目录
RUN mkdir -p /backup

# 复制备份脚本和crontab文件
COPY backup.sh /usr/local/bin/backup.sh
COPY crontab /etc/crontabs/root

# 设置脚本执行权限
RUN chmod +x /usr/local/bin/backup.sh

# 设置时区（根据需要修改）
RUN cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo "Asia/Shanghai" > /etc/timezone

# 启动cron
CMD ["crond", "-f", "-d", "8"]
