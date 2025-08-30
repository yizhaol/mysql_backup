import os
import requests
import time
import hmac
import hashlib
import base64
import urllib.parse


def send_dingtalk(msg: str):
    """发送钉钉消息通知"""
    webhook = os.environ.get("DINGTALK_WEBHOOK")
    secret = os.environ.get("DINGTALK_SECRET", "")

    if not webhook:
        return  # 没配置就直接跳过

    url = webhook
    headers = {"Content-Type": "application/json"}

    if secret:
        timestamp = str(round(time.time() * 1000))
        string_to_sign = f"{timestamp}\n{secret}"
        hmac_code = hmac.new(secret.encode("utf-8"), string_to_sign.encode("utf-8"),
                             digestmod=hashlib.sha256).digest()
        sign = urllib.parse.quote_plus(base64.b64encode(hmac_code))
        url = f"{webhook}&timestamp={timestamp}&sign={sign}"

    payload = {
        "msgtype": "text",
        "text": {"content": msg}
    }

    try:
        requests.post(url, headers=headers, json=payload, timeout=5)
    except Exception as e:
        print(f"[WARN] Failed to send DingTalk message: {e}", flush=True)
