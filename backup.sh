#!/bin/bash

# 获取当前时间作为备份文件名的一部分
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="/backups/backup_${MYSQL_DATABASE}_${TIMESTAMP}.sql.gz"

# 记录开始时间
echo "$(date +'%Y-%m-%d %H:%M:%S') - Starting backup of ${MYSQL_DATABASE} database" >> /var/log/cron.log

# 执行备份
if [ "$MYSQL_DATABASE" = "all" ]; then
    # 备份所有数据库
    mysqldump -h $MYSQL_HOST -P $MYSQL_PORT -u $MYSQL_USER -p$MYSQL_PASSWORD --all-databases | gzip > $BACKUP_FILE
else
    # 备份指定数据库
    mysqldump -h $MYSQL_HOST -P $MYSQL_PORT -u $MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE | gzip > $BACKUP_FILE
fi

# 检查备份是否成功
if [ $? -eq 0 ]; then
    echo "$(date +'%Y-%m-%d %H:%M:%S') - Backup successful: ${BACKUP_FILE}" >> /var/log/cron.log

    # 清理旧备份，只保留最近 MAX_BACKUPS 个备份
    ls -t /backups/backup_* | tail -n +$(($MAX_BACKUPS+1)) | xargs rm -f 2>/dev/null
else
    echo "$(date +'%Y-%m-%d %H:%M:%S') - Backup failed" >> /var/log/cron.log
    exit 1
fi