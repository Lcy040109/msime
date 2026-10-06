#!/usr/bin/env python3
"""更新下载的小响应必须复用 Android 共享有界 body 读取。"""
from pathlib import Path
import sys


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "platforms/android/java/app/msime/android/account/UpdateApi.java"


def main() -> int:
    source = SOURCE.read_text(encoding="utf-8")
    fetch_start = source.index("    byte[] fetch(String url, int maxBytes)")
    fetch_end = source.index("\n    }", fetch_start) + len("\n    }")
    fetch = source[fetch_start:fetch_end]
    checks = (
        ("HttpBodyPolicy.readBounded" in fetch, "没有使用 HttpBodyPolicy.readBounded"),
        ("ByteArrayOutputStream" not in fetch, "仍保留自定义 ByteArrayOutputStream 读取"),
        ("for (int read; (read = body.read(buffer)) != -1; )" not in fetch,
         "仍保留自定义响应读取循环"),
    )
    for passed, message in checks:
        if not passed:
            print(f"{SOURCE}: {message}", file=sys.stderr)
            return 1
    print("Android update responses use the shared bounded body policy")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
