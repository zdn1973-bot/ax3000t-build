#!/usr/bin/env bash
set -euo pipefail

KIT_DIR="$(cd "$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
WORKDIR="\${1:-$KIT_DIR/openwrt-v24.10.5}"
JOBS="\${JOBS:-2}"

if [[ ! -d "$WORKDIR/.git" ]]; then
  git clone --branch v24.10.5 --depth 1 https://github.com/openwrt/openwrt.git "$WORKDIR"
fi

"$KIT_DIR/apply.sh" "$WORKDIR"
cp "$KIT_DIR/config/dolphin-p1.seed" "$WORKDIR/.config"

cd "$WORKDIR"
./scripts/feeds update -a
./scripts/feeds install -a
make defconfig
make download -j"$JOBS"
make -j"$JOBS" V=s

echo
echo "Build outputs:"
find bin/targets/sunxi/cortexa7 -maxdepth 1 -type f -iname '*dolphin-p1*' -print | sort
