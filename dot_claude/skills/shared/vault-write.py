#!/usr/bin/env python3
"""
Obsidian Vault へのファイル書き込みヘルパー（共通）。

stdin からファイル内容を受け取り、指定パスに書き込む。
Windows Git Bash → WSL 間のシェルエスケープ問題を回避するため、
ファイル I/O を Python に集約する。

使い方:
  # 新規作成 / 上書き（プレーンテキスト）
  cat <<'EOF' | python3 vault-write.py /path/to/file.md
  ファイル内容...
  EOF

  # 新規作成 / 上書き（base64 エンコード — バッククォート等を含む場合）
  echo "$BASE64_CONTENT" | python3 vault-write.py --b64 /path/to/file.md

  # ファイル読み取り
  python3 vault-write.py --read /path/to/file.md

  # ファイル一覧（glob パターン）
  python3 vault-write.py --glob '/path/to/dir/*.md'

  # ファイル存在チェック
  python3 vault-write.py --exists /path/to/file.md
"""

import base64
import glob as glob_mod
import os
import sys


def cmd_write(path: str, decode_b64: bool = False) -> str:
    """stdin の内容をファイルに書き込む。ディレクトリがなければ作成。"""
    raw = sys.stdin.read()
    if decode_b64:
        content = base64.b64decode(raw.strip()).decode("utf-8")
    else:
        content = raw
    parent = os.path.dirname(path)
    if parent:
        os.makedirs(parent, exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)
    return f"written:{path}"


def cmd_read(path: str) -> str:
    """ファイルの内容を stdout に出力する。"""
    if not os.path.exists(path):
        print(f"ERROR: not found: {path}", file=sys.stderr)
        sys.exit(1)
    with open(path, "r", encoding="utf-8") as f:
        return f.read()


def cmd_glob(pattern: str) -> str:
    """glob パターンにマッチするファイルを改行区切りで出力する。"""
    files = sorted(glob_mod.glob(pattern))
    return "\n".join(files) if files else ""


def cmd_exists(path: str) -> str:
    """ファイルの存在を確認する。"""
    return "true" if os.path.exists(path) else "false"


def main():
    if len(sys.argv) < 2:
        print("Usage: vault-write.py [--read|--glob|--exists] <path>", file=sys.stderr)
        sys.exit(1)

    flag = sys.argv[1]

    if flag == "--read":
        print(cmd_read(sys.argv[2]), end="")
    elif flag == "--glob":
        print(cmd_glob(sys.argv[2]))
    elif flag == "--exists":
        print(cmd_exists(sys.argv[2]))
    elif flag == "--b64":
        # base64 デコードして書き込み（バッククォート等のエスケープ問題回避）
        print(cmd_write(sys.argv[2], decode_b64=True))
    elif flag.startswith("--"):
        print(f"ERROR: unknown flag: {flag}", file=sys.stderr)
        sys.exit(1)
    else:
        # デフォルト: 書き込み（stdin プレーンテキスト）
        print(cmd_write(flag))


if __name__ == "__main__":
    main()
