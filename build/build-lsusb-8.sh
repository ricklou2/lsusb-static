#!/bin/bash
# 离线编译 lsusb（usbutils 017 + libusb 1.0.27 + usb.ids 内嵌）
#   Linux(musl, zig)   : x86_64 / x86 / aarch64 / armhf
#   Android(NDK, API24): arm64-v8a / armeabi-v7a / x86 / x86_64
# 全程不联网：源码包、usb.ids、补丁都在 src/ 里。
#
# 用法:
#   ./build-lsusb-8.sh                 # 8 个目标全编
#   ONLY=android_arm64 ./build-lsusb-8.sh
#   ZIG=/opt/zig/zig NDK=/opt/android-ndk ./build-lsusb-8.sh
#
# 依赖: bash, tar, xz, bzip2, make, patch, python3
#       zig(带 cc)     -> Linux 目标
#       Android NDK r28 -> Android 目标
set -u

ROOT=$(cd "$(dirname "$0")" && pwd)
SRC=$ROOT/src
B=$ROOT/build
DEP=$B/dep
OUT=$ROOT/bins
W=$B/work

ZIG=${ZIG:-zig}
NDK=${NDK:-}
NB=${NB:-}
API=${API:-24}
JOBS=${JOBS:-$(nproc 2>/dev/null || echo 4)}
ONLY=${ONLY:-}

fail() { echo "!! $*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || fail "缺少命令: $1"; }

need tar; need xz; need bzip2; need make; need patch; need python3

# ---- NDK bin 目录 ----
if [ -z "$NB" ]; then
  if [ -n "$NDK" ]; then
    NB=$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin
  else
    for c in "$HOME"/android-sdk/ndk/*/toolchains/llvm/prebuilt/linux-x86_64/bin \
             /opt/android-ndk*/toolchains/llvm/prebuilt/linux-x86_64/bin; do
      [ -d "$c" ] && NB=$c && break
    done
  fi
fi
[ -n "$NB" ] && [ -x "$NB/llvm-strip" ] || fail "找不到 NDK（用 NDK=/path/to/ndk 指定）"
STRIP=$NB/llvm-strip
READELF=$NB/llvm-readelf

mkdir -p "$OUT" "$W" "$B/src"

# ---- 解包（只做一次）----
if [ ! -d "$B/src/libusb-1.0.27" ]; then
  echo "==> 解包 libusb-1.0.27"
  tar xjf "$SRC/libusb-1.0.27.tar.bz2" -C "$B/src" || fail "libusb 解包"
fi
if [ ! -d "$B/src/usbutils-017" ]; then
  echo "==> 解包 usbutils-017"
  tar xJf "$SRC/usbutils-017.tar.xz" -C "$B/src" || fail "usbutils 解包"
fi

# ---- usbutils 打补丁 + 内嵌 usb.ids ----
if [ ! -f "$B/src/usbutils-build/names.c" ]; then
  echo "==> 生成 usbutils-build（打补丁 + 内嵌 usb.ids）"
  python3 "$SRC/make_tree.py" \
      --usbutils "$B/src/usbutils-017" \
      --ids "$SRC/usb.ids" \
      --out "$B/src/usbutils-build" || fail "make_tree.py"
fi

# name        kind     triplet                       ndk-prefix                  out-name
TARGETS="
linux_x64,   linux,   x86_64-linux-musl,            -,                           linux-x64
linux_x86,   linux,   x86-linux-musl,               -,                           linux-x86
linux_arm64, linux,   aarch64-linux-musl,           -,                           linux-arm64
linux_armhf, linux,   arm-linux-musleabihf,         -,                           linux-armhf
android_x64, android, x86_64-linux-android,         x86_64-linux-android,        android-x64
android_x86, android, i686-linux-android,           i686-linux-android,          android-x86
android_arm64,android,aarch64-linux-android,        aarch64-linux-android,       android-arm64
android_arm, android, armv7a-linux-androideabi,     armv7a-linux-androideabi,    android-arm
"

build_one() {
  local name=$1 kind=$2 trip=$3 prefix=$4 outname=$5
  local bd=$W/$name dep=$DEP/$name

  if [ "$kind" = linux ]; then
    command -v "$ZIG" >/dev/null 2>&1 || fail "缺少 zig（用 ZIG=/path/to/zig 指定）"
    export CC="$ZIG cc -target $trip" AR="$ZIG ar" RANLIB="$ZIG ranlib"
    local CLINK="$ZIG cc -target $trip"
  else
    local cctrip="$trip$API"
    export CC="$NB/${prefix}${API}-clang" AR="$NB/llvm-ar" RANLIB="$NB/llvm-ranlib"
    local CLINK="$NB/${prefix}${API}-clang"
  fi

  mkdir -p "$bd" "$dep"

  echo "==> [$name] libusb (静态)"
  rm -rf "$bd" && mkdir -p "$bd"
  ( cd "$bd" && "$B/src/libusb-1.0.27/configure" \
      --host="$trip$([ "$kind" = android ] && echo "$API" || true)" \
      --build=x86_64-pc-linux-gnu \
      --prefix="$dep" --disable-shared --enable-static --disable-udev \
      > cfg.log 2>&1 && make -j"$JOBS" > mk.log 2>&1 && make install > inst.log 2>&1 ) \
    || { tail -25 "$bd/mk.log" 2>/dev/null; fail "[$name] libusb 编译失败"; }

  echo "==> [$name] lsusb"
  local ld=$bd/lsusb
  rm -rf "$ld" && mkdir -p "$ld"
  ( cd "$ld" && cat > config.h <<'EOF'
#define PACKAGE "usbutils"
#define PACKAGE_NAME "usbutils"
#define PACKAGE_VERSION "017"
#define PACKAGE_STRING "usbutils 017"
#define PACKAGE_TARNAME "usbutils"
#define PACKAGE_URL "http://www.kernel.org/pub/linux/utils/usb/usbutils/"
#define PACKAGE_BUGREPORT "linux-usb@vger.kernel.org"
#define VERSION "017"
#define HAVE_BYTESWAP_H 1
#define HAVE_INTTYPES_H 1
#define HAVE_STDINT_H 1
#define HAVE_STDIO_H 1
#define HAVE_STDLIB_H 1
#define HAVE_STRING_H 1
#define HAVE_STRINGS_H 1
#define HAVE_SYS_STAT_H 1
#define HAVE_SYS_TYPES_H 1
#define HAVE_UNISTD_H 1
#define HAVE_WCHAR_H 1
#define STDC_HEADERS 1
#define _FILE_OFFSET_BITS 64
EOF
    if [ "$kind" = linux ]; then
      printf '#define HAVE_ICONV 1\n#define HAVE_NL_LANGINFO 1\n' >> config.h
    fi
    $CLINK -static -O2 -DHAVE_CONFIG_H -I. -I"$dep/include/libusb-1.0" -I"$B/src/usbutils-build" \
      "$B/src/usbutils-build/lsusb.c" "$B/src/usbutils-build/lsusb-t.c" \
      "$B/src/usbutils-build/desc-defs.c" "$B/src/usbutils-build/desc-dump.c" \
      "$B/src/usbutils-build/names.c" "$B/src/usbutils-build/sysfs.c" \
      "$B/src/usbutils-build/usbmisc.c" "$B/src/usbutils-build/usb_ids_embedded.c" \
      "$dep/lib/libusb-1.0.a" -Wl,-z,max-page-size=16384 -o lsusb ) \
    || fail "[$name] lsusb 编译失败"

  "$STRIP" --strip-all "$ld/lsusb" || fail "[$name] strip 失败"
  cp "$ld/lsusb" "$OUT/lsusb-$outname"

  local interp align
  interp=$("$READELF" -l "$OUT/lsusb-$outname" | grep -c INTERP || true)
  align=$("$READELF" -l "$OUT/lsusb-$outname" | awk '/LOAD/{print $NF}' | sort -u | tr '\n' ' ')
  printf '    -> bins/lsusb-%-13s %8d B  interp=%s  align=%s\n' \
      "$outname" "$(stat -c%s "$OUT/lsusb-$outname")" "$interp" "$align"
}

while IFS=',' read -r name kind trip prefix outname; do
  name=$(echo "$name" | tr -d ' ')
  [ -z "$name" ] && continue
  kind=$(echo "$kind" | tr -d ' ')
  trip=$(echo "$trip" | tr -d ' ')
  prefix=$(echo "$prefix" | tr -d ' ')
  outname=$(echo "$outname" | tr -d ' ')
  [ "$prefix" = "-" ] && prefix=""
  if [ -n "$ONLY" ] && [ "$ONLY" != "$name" ]; then continue; fi
  build_one "$name" "$kind" "$trip" "$prefix" "$outname"
done <<< "$TARGETS"

echo
echo "==== 产物（$OUT）===="
ls -l "$OUT"
echo
echo "校验（应全部 statically linked / interp=0 / align 0x4000）："
for f in "$OUT"/lsusb-*; do
  printf '%-28s %s\n' "$(basename "$f")" \
    "$($READELF -l "$f" | awk '/LOAD/{print $NF}' | sort -u | tr '\n' ' ')"
done
