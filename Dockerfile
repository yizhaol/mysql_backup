FROM alpine:3.14

# 安装必要的软件包
RUN apk add --no-cache mysql-client bash tzdata

# 设置时区
RUN cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo "Asia/Shanghai" > /etc/timezone

# 创建脚本目录并复制备份脚本
RUN mkdir -p /scripts
COPY scripts/backup.sh /scripts/backup.sh
RUN chmod +x /scripts/backup.sh

# 设置备份目录
VOLUME /backups

# 设置默认的环境变量（作为文档说明，实际值从.env文件读取）
ENV MYSQL_HOST="please_set_in_env_file" \
    MYSQL_PORT="3306" \
    MYSQL_DATABASE="please_set_in_env_file" \
    MYSQL_USER="please_set_in_env_file" \
    MYSQL_PASSWORD="please_set_in_env_file" \
    BACKUP_SCHEDULE="0 2 * * *" \
    BACKUP_RETENTION_DAYS="30"

# 启动命令
CMD ["sh", "-c", "echo '${BACKUP_SCHEDULE} /scripts/backup.sh >> /backups/backup.log 2>&1' > /var/spool/cron/crontabs/root && crond -f -l 8"]