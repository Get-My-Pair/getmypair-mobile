import base64
import hashlib
import shutil
import subprocess
from pathlib import Path

jks = Path(__file__).resolve().parent / "getmypair-release.jks"
alias = "getmypair"
storepass = "getmypair"
pkg = "com.getmypair.userapp"

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
