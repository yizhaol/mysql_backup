import os
import time
import schedule
import subprocess
from datetime import datetime


def run_backup():
    """执行一次备份"""
    print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Running backup...")
    try:
        subprocess.run(["python", "backup.py"])
    except subprocess.CalledProcessError as e:
        print(f"[ERROR] Backup process failed: {e}", flush=True)


def main():
    # 从环境变量获取时间，默认 02:00
    backup_time = os.environ.get("BACKUP_TIME", "02:00")
    # 立即先执行一次备份
    run_backup()
    # 设置每天定时任务
    schedule.every().day.at(backup_time).do(run_backup)
    print(f"Backup scheduler started. Scheduled daily at {backup_time}.")

    # 循环等待
    while True:
        schedule.run_pending()
        time.sleep(30)


if __name__ == "__main__":

    main()
