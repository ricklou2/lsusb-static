# lsusb — Fully Static Build (8 targets)

**Languages:** [English](#english) | [简体中文](#简体中文) | [繁體中文](#繁體中文)

---

## English

A standalone, fully static build of **lsusb**, a USB device listing tool (usbutils + libusb) with usb.ids embedded. Eight executables are provided — four for Linux (musl) and four for Android (NDK, API 24) — together with the upstream source and build scripts. The binaries have no dynamic interpreter and no shared-library dependencies, and are aligned to 16 KB pages, so they run on Android phones (Android 7–16), embedded devices, and minimal Linux systems.

**Upstream version:** usbutils 017 + libusb 1.0.27

### Executables

| File | Size | MD5 |
|---|---:|---|
| lsusb-android-arm | 1,210,540 B | `945cb359bda7ebffa0b57bd3507903d3` |
| lsusb-android-arm64 | 1,405,096 B | `fb5819559b6cbb7ba811c051acf96e08` |
| lsusb-android-x64 | 1,405,584 B | `cef7e4b022318cea5736dcfe1d46db3c` |
| lsusb-android-x86 | 1,401,364 B | `3a9b4a86cc2d6ffc2cb53603f174f847` |
| lsusb-linux-arm64 | 1,201,464 B | `54e86cc0f0cfaf56401d6ec10299026f` |
| lsusb-linux-armhf | 1,152,836 B | `296bfc7e112a7db0204c4218bc5b0d18` |
| lsusb-linux-x64 | 1,197,088 B | `ab5d2bdd7d7e623068e2229b9420559c` |
| lsusb-linux-x86 | 1,154,028 B | `58a3df81154931173711258de88be565` |

### Static verification

```bash
readelf -l <binary> | grep -c INTERP   # 0
readelf -l <binary> | grep LOAD        # align 0x4000 (16 KB)
file <binary>                         # statically linked
```

### Install and run

```bash
# Linux
install -m755 bins/lsusb-linux-x64 /usr/local/bin/lsusb
lsusb

# Android (via adb)
adb push bins/lsusb-android-arm64 /data/local/tmp/lsusb
adb shell "chmod 755 /data/local/tmp/lsusb"
adb shell "/data/local/tmp/lsusb"
```

### Repository layout

```
bins/     Eight executables (linux & android, x64/x86/arm64/arm)
build/    Build scripts
src/      Upstream source
```

### Offline build

The source and build scripts are included for fully offline reproduction. The Linux targets use zig (musl cross-compilation) and the Android targets use the NDK (API 24):

```bash
# Run the bundled build script (see build/)
sh build/build-lsusb-8.sh
```

| Target | Linux triple | Android triple |
|---|---|---|
| x64 | x86_64-linux-musl | x86_64-linux-android24 |
| x86 | x86-linux-musl | i686-linux-android24 |
| arm64 | aarch64-linux-musl | aarch64-linux-android24 |
| arm | arm-linux-musleabihf | armv7a-linux-androideabi24 |

---

## 简体中文

**lsusb** 的独立全静态构建包，USB 设备列出工具（usbutils + libusb），usb.ids 已内嵌。共提供 8 个可执行文件——Linux（musl）4 个、Android（NDK，API 24）4 个，并附上游源码与构建脚本。可执行文件无动态解释器、无共享库依赖，按 16 KB 页对齐，可在安卓手机（Android 7–16）、嵌入式设备和精简 Linux 系统上运行。

**上游版本：**usbutils 017 + libusb 1.0.27

### 可执行文件

| 文件 | Size | MD5 |
|---|---:|---|
| lsusb-android-arm | 1,210,540 B | `945cb359bda7ebffa0b57bd3507903d3` |
| lsusb-android-arm64 | 1,405,096 B | `fb5819559b6cbb7ba811c051acf96e08` |
| lsusb-android-x64 | 1,405,584 B | `cef7e4b022318cea5736dcfe1d46db3c` |
| lsusb-android-x86 | 1,401,364 B | `3a9b4a86cc2d6ffc2cb53603f174f847` |
| lsusb-linux-arm64 | 1,201,464 B | `54e86cc0f0cfaf56401d6ec10299026f` |
| lsusb-linux-armhf | 1,152,836 B | `296bfc7e112a7db0204c4218bc5b0d18` |
| lsusb-linux-x64 | 1,197,088 B | `ab5d2bdd7d7e623068e2229b9420559c` |
| lsusb-linux-x86 | 1,154,028 B | `58a3df81154931173711258de88be565` |

### 静态性核验

```bash
readelf -l <二进制> | grep -c INTERP   # 0
readelf -l <二进制> | grep LOAD        # align 0x4000（16 KB）
file <二进制>                         # statically linked
```

### 安装与运行

```bash
# Linux
install -m755 bins/lsusb-linux-x64 /usr/local/bin/lsusb
lsusb

# Android（通过 adb）
adb push bins/lsusb-android-arm64 /data/local/tmp/lsusb
adb shell "chmod 755 /data/local/tmp/lsusb"
adb shell "/data/local/tmp/lsusb"
```

### 仓库结构

```
bins/     八个可执行文件（linux 与 android，x64/x86/arm64/arm）
build/    构建脚本
src/      上游源码
```

### 离线编译

源码与构建脚本已包含，可完全离线复现。Linux 目标使用 zig（musl 交叉编译），Android 目标使用 NDK（API 24）：

```bash
# 运行附带的构建脚本（见 build/）
sh build/build-lsusb-8.sh
```

| 目标 | Linux triple | Android triple |
|---|---|---|
| x64 | x86_64-linux-musl | x86_64-linux-android24 |
| x86 | x86-linux-musl | i686-linux-android24 |
| arm64 | aarch64-linux-musl | aarch64-linux-android24 |
| arm | arm-linux-musleabihf | armv7a-linux-androideabi24 |

---

## 繁體中文

**lsusb** 的獨立全靜態建構包，USB 裝置列出工具（usbutils + libusb），usb.ids 已內嵌。共提供 8 個可執行檔——Linux（musl）4 個、Android（NDK，API 24）4 個，並附上游原始碼與建構腳本。可執行檔無動態直譯器、無共用程式庫相依性，按 16 KB 頁對齊，可在安卓手機（Android 7–16）、嵌入式裝置和精簡 Linux 系統上執行。

**上游版本：**usbutils 017 + libusb 1.0.27

### 可執行檔

| 檔案 | Size | MD5 |
|---|---:|---|
| lsusb-android-arm | 1,210,540 B | `945cb359bda7ebffa0b57bd3507903d3` |
| lsusb-android-arm64 | 1,405,096 B | `fb5819559b6cbb7ba811c051acf96e08` |
| lsusb-android-x64 | 1,405,584 B | `cef7e4b022318cea5736dcfe1d46db3c` |
| lsusb-android-x86 | 1,401,364 B | `3a9b4a86cc2d6ffc2cb53603f174f847` |
| lsusb-linux-arm64 | 1,201,464 B | `54e86cc0f0cfaf56401d6ec10299026f` |
| lsusb-linux-armhf | 1,152,836 B | `296bfc7e112a7db0204c4218bc5b0d18` |
| lsusb-linux-x64 | 1,197,088 B | `ab5d2bdd7d7e623068e2229b9420559c` |
| lsusb-linux-x86 | 1,154,028 B | `58a3df81154931173711258de88be565` |

### 靜態性核驗

```bash
readelf -l <可執行檔> | grep -c INTERP   # 0
readelf -l <可執行檔> | grep LOAD        # align 0x4000（16 KB）
file <可執行檔>                         # statically linked
```

### 安裝與執行

```bash
# Linux
install -m755 bins/lsusb-linux-x64 /usr/local/bin/lsusb
lsusb

# Android（透過 adb）
adb push bins/lsusb-android-arm64 /data/local/tmp/lsusb
adb shell "chmod 755 /data/local/tmp/lsusb"
adb shell "/data/local/tmp/lsusb"
```

### 倉庫結構

```
bins/     八個可執行檔（linux 與 android，x64/x86/arm64/arm）
build/    建構腳本
src/      上游原始碼
```

### 離線建構

原始碼與建構腳本已包含，可完全離線重現。Linux 目標使用 zig（musl 交叉編譯），Android 目標使用 NDK（API 24）：

```bash
# 執行附帶的建構腳本（見 build/）
sh build/build-lsusb-8.sh
```

| 目標 | Linux triple | Android triple |
|---|---|---|
| x64 | x86_64-linux-musl | x86_64-linux-android24 |
| x86 | x86-linux-musl | i686-linux-android24 |
| arm64 | aarch64-linux-musl | aarch64-linux-android24 |
| arm | arm-linux-musleabihf | armv7a-linux-androideabi24 |
