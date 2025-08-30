import os
import subprocess
import requests
import hmac
import hashlib
import base64
import urllib.parse
import time
from datetime import datetime

# ========== 日志函数 ==========
def log(msg):
    print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] {msg}", flush=True)


# ========== 执行 mysql 命令并返回输出 ==========
def run_mysql_cmd(cmd):
    try:
        output = subprocess.check_output(
            cmd,
            stderr=subprocess.DEVNULL,   # 屏蔽告警输出，避免混进结果
            universal_newlines=True
        )
        return output.strip()
    except subprocess.CalledProcessError as e:
        log(f"[ERROR] Command failed: {' '.join(cmd)}\n{e}")
        return ""


# ========== 获取数据库列表 ==========
def get_databases():
    host = os.environ["MYSQL_HOST"]
    port = os.environ.get("MYSQL_PORT", "3306")
    user = os.environ["MYSQL_USER"]
    password = os.environ["MYSQL_PASSWORD"]

    ssl_mode = os.environ.get("MYSQL_SSL", "REQUIRED").upper()
    ssl_flag = f"--ssl-mode={ssl_mode}"

    cmd = [
        "mysql",
        f"-h{host}", f"-P{port}", f"-u{user}", f"-p{password}",
        ssl_flag,
        "--skip-column-names",
        "-e", "SHOW DATABASES;"
    ]
    output = run_mysql_cmd(cmd)
    if not output:
        return []

    all_dbs = output.splitlines()
    exclude = {"information_schema", "performance_schema", "mysql", "sys"}
    return [db.strip() for db in all_dbs if db.strip() and db not in exclude]


# ========== 备份一次 ==========
def backup_once():
    backup_dir = os.environ.get("BACKUP_DIR", "/backups")
    os.makedirs(backup_dir, exist_ok=True)

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    host = os.environ["MYSQL_HOST"]
    port = os.environ.get("MYSQL_PORT", "3306")
    user = os.environ["MYSQL_USER"]
    password = os.environ["MYSQL_PASSWORD"]

    ssl_mode = os.environ.get("MYSQL_SSL", "REQUIRED").upper()
    ssl_flag = f"--ssl-mode={ssl_mode}"

    databases = get_databases()
    if not databases:
        log("[WARN] No databases found to backup.")
        return []

    success_files = []
    for db in databases:
        filename = f"{backup_dir}/{db}_{timestamp}.sql.gz"
        cmd = [
            "mysqldump",
            f"-h{host}", f"-P{port}", f"-u{user}", f"-p{password}",
            ssl_flag,
            db
        ]

        log(f"Backing up database: {db}")
        try:
            with open(filename, "wb") as f:
                p1 = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)  # 屏蔽 mysqldump 告警
                p2 = subprocess.Popen(["gzip"], stdin=p1.stdout, stdout=f)
                p1.stdout.close()
                p2.communicate()
            log(f"[OK] Backup saved: {filename}")
            success_files.append(filename)
        except Exception as e:
            log(f"[ERROR] Backup failed for {db}: {e}")

    return success_files


# ========== 钉钉推送（支持加签） ==========
def send_dingtalk_notification(success_files):
    webhook = os.environ.get("DINGTALK_WEBHOOK")
    secret = os.environ.get("DINGTALK_SECRET")
    if not webhook:
        log("[INFO] Dingtalk webhook not configured, skip notification.")
        return

    if success_files:
        msg = "✅ MySQL 备份完成:\n" + "\n".join(success_files)
    else:
        msg = "⚠️ MySQL 备份失败，没有生成任何文件！"

    url = webhook
    if secret:  # 加签模式
        timestamp = str(round(time.time() * 1000))
        string_to_sign = f"{timestamp}\n{secret}"
        hmac_code = hmac.new(
            secret.encode("utf-8"),
            string_to_sign.encode("utf-8"),
            digestmod=hashlib.sha256
        ).digest()
        sign = urllib.parse.quote_plus(base64.b64encode(hmac_code))
        url = f"{webhook}&timestamp={timestamp}&sign={sign}"

    payload = {
        "msgtype": "text",
        "text": {"content": msg}
    }

    try:
        r = requests.post(url, json=payload, timeout=10)
        if r.status_code == 200:
            log("[OK] Dingtalk notification sent.")
        else:
            log(f"[ERROR] Dingtalk notification failed: {r.text}")
    except Exception as e:
        log(f"[ERROR] Dingtalk request exception: {e}")


# ========== 主程序入口 ==========
if __name__ == "__main__":
    log("Running backup once...")
    files = backup_once()
    send_dingtalk_notification(files)
