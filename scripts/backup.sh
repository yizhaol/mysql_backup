#!/bin/bash

# 记录开始时间
echo "$(date): Starting backup script..."

# 检查必要环境变量是否设置
if [ -z "${MYSQL_HOST}" ] || [ -z "${MYSQL_USER}" ] || [ -z "${MYSQL_PASSWORD}" ] || [ -z "${MYSQL_DATABASE}" ]; then
    echo "Error: Required MySQL environment variables are not set."
    echo "Please set MYSQL_HOST, MYSQL_USER, MYSQL_PASSWORD and MYSQL_DATABASE in docker-compose.yml"
    exit 1
fi

# 设置变量默认值
MYSQL_PORT=${MYSQL_PORT:-3306}
BACKUP_DIR=${BACKUP_DIR:-/backups}
BACKUP_RETENTION_DAYS=${BACKUP_RETENTION_DAYS:-30}

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/${MYSQL_DATABASE}_backup_${TIMESTAMP}.sql"

echo "$(date): Attempting to backup database ${MYSQL_DATABASE} from host ${MYSQL_HOST}..."

# 使用环境变量中的配置执行备份
mysqldump \
    --host="${MYSQL_HOST}" \
    --port="${MYSQL_PORT}" \
    --user="${MYSQL_USER}" \
    --password="${MYSQL_PASSWORD}" \
    --single-transaction \
    --routines \
    --triggers \
    "${MYSQL_DATABASE}" > "${BACKUP_FILE}"

# 检查备份结果
if [ $? -eq 0 ]; then
    echo "$(date): Backup successful: ${BACKUP_FILE}"

    # 压缩备份文件
    gzip "${BACKUP_FILE}"
    echo "$(date): Backup compressed: ${BACKUP_FILE}.gz"

    # 清理旧备份
    find "${BACKUP_DIR}" -name "*.sql.gz" -type f -mtime +${BACKUP_RETENTION_DAYS} -delete
    echo "$(date): Old backups older than ${BACKUP_RETENTION_DAYS} days cleaned up."
else
    echo "$(date): Backup failed! Please check your database connection settings and permissions."
    # 删除可能不完整的备份文件
    rm -f "${BACKUP_FILE}"
    exit 1
fi