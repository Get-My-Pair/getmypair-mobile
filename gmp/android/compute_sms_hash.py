"""Compute Android SMS Retriever app hash from the release keystore.

Credentials must come from environment variables or android/key.properties
(never hardcode passwords in this script).
"""
import base64
import hashlib
import os
import shutil
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parent
KEY_PROPS = ROOT / "key.properties"


def _load_key_properties() -> dict[str, str]:
    props: dict[str, str] = {}
    if not KEY_PROPS.exists():
        return props
    for line in KEY_PROPS.read_text(encoding="utf-8").splitlines():
        raw = line.strip()
        if not raw or raw.startswith("#") or "=" not in raw:
            continue
        key, value = raw.split("=", 1)
        props[key.strip()] = value.strip()
    return props


props = _load_key_properties()

jks_name = (
    os.environ.get("MYAPP_UPLOAD_STORE_FILE")
    or props.get("storeFile")
    or props.get("MYAPP_UPLOAD_STORE_FILE")
    or "getmypair-release.jks"
)
jks = Path(jks_name)
if not jks.is_absolute():
    jks = (ROOT / jks).resolve()

alias = (
    os.environ.get("MYAPP_UPLOAD_KEY_ALIAS")
    or props.get("keyAlias")
    or props.get("MYAPP_UPLOAD_KEY_ALIAS")
)
storepass = (
    os.environ.get("MYAPP_UPLOAD_STORE_PASSWORD")
    or props.get("storePassword")
    or props.get("MYAPP_UPLOAD_STORE_PASSWORD")
)
pkg = "com.getmypair.userapp"

if not alias or not storepass:
    raise SystemExit(
        "Missing keystore alias/password. Set MYAPP_UPLOAD_KEY_ALIAS and "
        "MYAPP_UPLOAD_STORE_PASSWORD, or create android/key.properties from "
        "key.properties.example (and rotate any previously committed password)."
    )
if not jks.exists():
    raise SystemExit(f"Keystore not found: {jks}")

candidates = [
    r"C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe",
    r"C:\Program Files\Java\jdk-17\bin\keytool.exe",
]
kt = next((c for c in candidates if Path(c).exists()), shutil.which("keytool"))
if not kt:
    raise SystemExit("keytool not found")

print("using", kt)
der = subprocess.check_output(
    [
        kt,
        "-exportcert",
        "-alias",
        alias,
        "-keystore",
        str(jks),
        "-storepass",
        storepass,
    ],
    stderr=subprocess.DEVNULL,
)

digest = hashlib.sha256(pkg.encode("ascii") + b" " + der).digest()
sig = base64.b64encode(digest).decode("ascii")[:11]
print("APP_HASH=", sig)
