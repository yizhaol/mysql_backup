FROM alpine:3.16

# 安装必要的软件包
RUN apk update && \
    apk add --no-cache bash mysql-client curl && \
    rm -rf /var/cache/apk/*

# 创建备份目录
RUN mkdir -p /backups

# 复制备份脚本
COPY backup.sh /usr/local/bin/backup.sh
RUN chmod +x /usr/local/bin/backup.sh

# 复制cron任务
COPY cronjobs /etc/cron.d/backup-cron
RUN chmod 0644 /etc/cron.d/backup-cron

# 安装cron
RUN apk add --no-cache busybox-suid && \
    crontab /etc/cron.d/backup-cron

# 添加环境变量默认值
ENV MYSQL_HOST=mysql-host \
    MYSQL_PORT=3306 \
    MYSQL_USER=root \
    MYSQL_PASSWORD=password \
    MYSQL_DATABASE=all \
    BACKUP_INTERVAL=daily \
    MAX_BACKUPS=7

# 创建日志文件
RUN touch /var/log/cron.log

# 启动cron并保持容器运行
CMD printenv > /etc/environment && \
    echo "Starting backup container with the following settings:" && \
    echo "MySQL Host: $MYSQL_HOST" && \
    echo "MySQL Port: $MYSQL_PORT" && \
    echo "MySQL User: $MYSQL_USER" && \
    echo "MySQL Database: $MYSQL_DATABASE" && \
    echo "Backup Interval: $BACKUP_INTERVAL" && \
    echo "Max Backups: $MAX_BACKUPS" && \
    crond -l 2 -L /var/log/cron.log && \
    tail -f /var/log/cron.log