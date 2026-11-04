# OpenWrt 24.10.5 — MBOX Dolphin-P1 (Allwinner H3)

This branch contains an experimental source port and GitHub Actions build workflow for SD-card boot only.

## Build

The workflow starts automatically when project files are pushed to this branch. Open the repository Actions tab to follow the build. A successful run uploads the compressed SD-card image and SHA256 checksum as an artifact.

The workflow checks out upstream OpenWrt tag \`v24.10.5\`, applies the board patch and local build configuration, then builds the \`sunxi/cortexa7\` target.

## Hardware facts used

- SoC: Allwinner H3 / Cortex-A7
- Board identifier from vendor config: \`dolphin-p1\`
- Vendor Ethernet setting: \`gmac_used = 2\` (internal PHY)
- SD socket: MMC0, PF pin group, card detect on PF6
- UART0 pins: PA04/PA05
- Wi-Fi/SDIO is intentionally not enabled in this first bring-up image.

## Important experimental limitations

This is not an upstream-supported OpenWrt board profile. The build uses the documented \`orangepi_plus2e_defconfig\` as a starting point for U-Boot because the Dolphin-P1 mainline bring-up notes identify it. The U-Boot DRAM clock is overridden to 576 MHz to match the vendor config. Other DRAM timings and bootloader compatibility have not yet been validated on this exact PCB revision.

The DTS, U-Boot, rootfs and complete SD-card image must pass build and hardware testing. A successful compilation does **not** prove that the image will boot on the TV box.

Do not flash internal NAND/eMMC. The generated image is for a removable SD card only. Keep the original Android storage untouched. If the first boot fails, do not try random DTB replacements; capture the boot log through UART before changing the image.

## Sources

- Vendor Dolphin-P1 config: https://github.com/friendlyarm/h3_lichee/blob/master/tools/pack/chips/sun8iw7p1/configs/dolphin-p1/sys_config.fex
- Dolphin-P1 H3 mainline bring-up: https://github.com/M0Rf30/h3-dolphin-p1
- OpenWrt 24.10.5 sunxi image recipe: https://github.com/openwrt/openwrt/blob/v24.10.5/target/linux/sunxi/image/Makefile
