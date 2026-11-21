#!/usr/bin/env python3
"""
把 usbutils 017 源码树变成「可直接编译、usb.ids 内嵌」的树。

用法：
  python3 make_tree.py --usbutils <解压后的 usbutils-017> --ids <usb.ids> --out <输出目录>

做三件事：
  1) 打 patches/usbutils-017-noudev.patch：libudev 变可选，无 udev 时回退 usb.ids 文本查表；
  2) 用 usb.ids 生成 usb_ids_embedded.c（按行拼 C 字符串，每段 ≤400 字符）；
  3) 改 names.c：load_usb_ids() 直接把指针指向内嵌表（不 fopen），names_exit() 不 free。
"""
import argparse
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent


def esc(s: str) -> str:
    return s.replace("\\", "\\\\").replace('"', '\\"')


def gen_embedded(ids_path: Path, out_path: Path) -> int:
    text = ids_path.read_text(encoding="utf-8", errors="replace")
    chunks, buf = [], ""
    for line in text.split("\n"):
        buf += esc(line) + "\\n"
        if len(buf) >= 400:
            chunks.append(buf)
            buf = ""
    if buf:
        chunks.append(buf)

    lines = [
        "/* 由 usb.ids 生成（%d 行），供 lsusb 内嵌查表，勿手改 */" % text.count("\n"),
        "const char usb_ids_embedded[] =",
    ]
    for c in chunks:
        lines.append('    "%s"' % c)
    lines.append("    ;")
    out_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    return len(chunks)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--usbutils", required=True)
    ap.add_argument("--ids", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--patch", default=str(HERE / "patches" / "usbutils-017-noudev.patch"))
    a = ap.parse_args()

    src, out = Path(a.usbutils), Path(a.out)
    if not (src / "names.c").exists():
        print("!! %s 不像 usbutils 源码树" % src, file=sys.stderr)
        return 1

    if out.exists():
        shutil.rmtree(out)
    shutil.copytree(src, out)

    # 1) 无 udev 回退补丁
    print("==> patch %s" % Path(a.patch).name)
    r = subprocess.run(["patch", "-p1", "-d", str(out), "-i", str(Path(a.patch).resolve())],
                       stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    print(r.stdout.strip())
    if r.returncode != 0:
        print("!! 补丁失败", file=sys.stderr)
        return r.returncode

    # 2) 生成内嵌表
    n = gen_embedded(Path(a.ids), out / "usb_ids_embedded.c")
    print("==> usb_ids_embedded.c：%d 个字面量" % n)

    # 3) names.c：指向内嵌表，且不再 free
    p = out / "names.c"
    s = p.read_text(encoding="utf-8")

    start = s.index("static int load_usb_ids(void)")
    end = s.index("\n}\n", start) + 3
    new_fn = (
        "extern const char usb_ids_embedded[];\n"
        "static int load_usb_ids(void)\n"
        "{\n"
        "\t/* 内嵌 usb.ids：不读任何文件，指针直接指向 rodata */\n"
        "\tusb_ids_buf = (char *)usb_ids_embedded;\n"
        "\treturn 0;\n"
        "}\n"
    )
    s = s[:start] + new_fn + s[end:]

    s = s.replace(
        "\tif (usb_ids_buf) {\n"
        "\t\tfree(usb_ids_buf);\n"
        "\t\tusb_ids_buf = NULL;\n"
        "\t}\n",
        "\t/* usb_ids_buf 指向内嵌只读表，不能 free */\n",
    )
    if "不能 free" not in s:
        print("!! names_exit 改写失败", file=sys.stderr)
        return 1
    p.write_text(s, encoding="utf-8")

    print("==> 完成：%s" % out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
