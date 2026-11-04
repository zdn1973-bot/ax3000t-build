#!/usr/bin/env bash
set -euo pipefail

KIT_DIR="$(cd "$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
OPENWRT_DIR="\${1:-}"
if [[ -z "$OPENWRT_DIR" || ! -d "$OPENWRT_DIR/target/linux/sunxi" ]]; then
  echo "Usage: $0 /path/to/openwrt-v24.10.5" >&2
  exit 2
fi

cd "$OPENWRT_DIR"
if ! git describe --tags --exact-match HEAD 2>/dev/null | grep -qx 'v24.10.5'; then
  echo "ERROR: this kit targets the OpenWrt v24.10.5 source tag." >&2
  echo "Current checkout: $(git describe --tags --always 2>/dev/null || echo unknown)" >&2
  exit 3
fi

mkdir -p target/linux/sunxi/patches-6.6
cp "$KIT_DIR/patches/950-dts-sun8i-h3-dolphin-p1.patch" \
   target/linux/sunxi/patches-6.6/950-dts-sun8i-h3-dolphin-p1.patch

python3 - <<'PY'
from pathlib import Path

p = Path("target/linux/sunxi/image/cortexa7.mk")
s = p.read_text()
marker = "TARGET_DEVICES += m0rf30_dolphin-p1"
if marker not in s:
    s += """

# MBOX Dolphin-P1 (Allwinner H3) - experimental SD-card profile
# Wired Ethernet only for initial bring-up; Wi-Fi is intentionally omitted.
define Device/m0rf30_dolphin-p1
  DEVICE_VENDOR := MBOX
  DEVICE_MODEL := Dolphin-P1
  SOC := sun8i-h3
endef
TARGET_DEVICES += m0rf30_dolphin-p1
"""
    p.write_text(s)

p = Path("target/linux/sunxi/config-6.6")
s = p.read_text()
old = "# CONFIG_DWMAC_SUN8I is not set"
if old in s:
    s = s.replace(old, "CONFIG_DWMAC_SUN8I=y")
elif "CONFIG_DWMAC_SUN8I=y" not in s:
    s += "\nCONFIG_DWMAC_SUN8I=y\n"
p.write_text(s)

p = Path("package/boot/uboot-sunxi/Makefile")
s = p.read_text()
variant = """define U-Boot/dolphin_p1
  BUILD_SUBTARGET:=cortexa7
  NAME:=MBOX Dolphin-P1 (H3)
  BUILD_DEVICES:=m0rf30_dolphin-p1
  UBOOT_CONFIG:=orangepi_plus2e
  UBOOT_CUSTOMIZE_CONFIG:=--set-val CONFIG_DRAM_CLK 576
endef

"""
if "define U-Boot/dolphin_p1" not in s:
    anchor = "UBOOT_TARGETS := \\\n"
    if anchor not in s:
        raise SystemExit("Could not find UBOOT_TARGETS anchor in uboot-sunxi/Makefile")
    s = s.replace(anchor, variant + anchor, 1)
    anchor2 = "\torangepi_pc_plus \\\n"
    if anchor2 not in s:
        raise SystemExit("Could not find orangepi_pc_plus entry in UBOOT_TARGETS")
    s = s.replace(anchor2, anchor2 + "\tdolphin_p1 \\\n", 1)
    p.write_text(s)

print("Applied Dolphin-P1 source changes to", Path.cwd())
PY

echo "Applied. Next: copy config/dolphin-p1.seed to .config, then run make defconfig."
