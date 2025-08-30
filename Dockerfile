# 阶段1：从官方 MySQL 镜像获取 mysqldump 和 mysql 客户端
FROM mysql:8.0 as mysql-client

# 阶段2：Python 应用镜像
FROM python:3.10-slim

# 安装 MySQL 客户端运行依赖
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        libncurses6 \
        libtinfo6 \
        libssl3 \
    && rm -rf /var/lib/apt/lists/*

# 配置时区
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 拷贝 MySQL 客户端工具 (mysqldump, mysql) 到 Python 镜像
COPY --from=mysql-client /usr/bin/mysqldump /usr/bin/mysql /usr/bin/

# 创建工作目录
WORKDIR /app
RUN mkdir -p /backups

# 拷贝应用代码
COPY backup.py scheduler.py notifier.py /app/

# 安装 Python 依赖
RUN pip install --no-cache-dir requests schedule

# 声明挂载点
VOLUME ["/backups"]

# 默认启动
CMD ["python", "scheduler.py"]
