#!/bin/bash

# 设置变量
BACKUP_DIR="/backup"
MYSQL_HOST="${MYSQL_HOST}"
MYSQL_PORT="${MYSQL_PORT:-3306}"
MYSQL_USER="${MYSQL_USER}"
MYSQL_PASSWORD="${MYSQL_PASSWORD}"
DATABASES="${DATABASES:-all}"
RETENTION_DAYS="${RETENTION_DAYS:-7}"

# 创建备份目录
mkdir -p "$BACKUP_DIR"

# 设置日期格式
DATE=$(date +%Y%m%d_%H%M%S)

# 记录日志
echo "$(date +"%Y-%m-%d %H:%M:%S") - 开始备份数据库" >> "$BACKUP_DIR/backup.log"

# 备份所有数据库或指定数据库
if [ "$DATABASES" = "all" ]; then
    # 备份所有数据库
    mysqldump --host="$MYSQL_HOST" --port="$MYSQL_PORT" --user="$MYSQL_USER" --password="$MYSQL_PASSWORD" --all-databases --single-transaction > "$BACKUP_DIR/all_databases_$DATE.sql" 2>> "$BACKUP_DIR/backup.log"
    
    # 压缩备份文件
    gzip "$BACKUP_DIR/all_databases_$DATE.sql"
    
    echo "$(date +"%Y-%m-%d %H:%M:%S") - 所有数据库已备份: all_databases_$DATE.sql.gz" >> "$BACKUP_DIR/backup.log"
else
    # 备份指定数据库
    IFS=',' read -ra DB_ARRAY <<< "$DATABASES"
    for db in "${DB_ARRAY[@]}"; do
        mysqldump --host="$MYSQL_HOST" --port="$MYSQL_PORT" --user="$MYSQL_USER" --password="$MYSQL_PASSWORD" --databases "$db" --single-transaction > "$BACKUP_DIR/${db}_$DATE.sql" 2>> "$BACKUP_DIR/backup.log"
        
        # 压缩备份文件
        gzip "$BACKUP_DIR/${db}_$DATE.sql"
        
        echo "$(date +"%Y-%m-%d %H:%M:%S") - 数据库 $db 已备份: ${db}_$DATE.sql.gz" >> "$BACKUP_DIR/backup.log"
    done
fi

# 删除旧备份（保留指定天数的备份）
find "$BACKUP_DIR" -name "*.sql.gz" -type f -mtime +$RETENTION_DAYS -delete
echo "$(date +"%Y-%m-%d %H:%M:%S") - 已删除超过 $RETENTION_DAYS 天的备份文件" >> "$BACKUP_DIR/backup.log"
