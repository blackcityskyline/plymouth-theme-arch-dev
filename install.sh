#!/bin/bash
set -euo pipefail

THEME_NAME="arch-dev"
THEME_DIR="/usr/share/plymouth/themes/${THEME_NAME}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMPLATE="${SCRIPT_DIR}/assets/arch-dev.script"

if [ "$(id -u)" -ne 0 ]; then
    echo "Run as root"
    exit 1
fi

# ---- Vendor logo position ----
echo ""
echo "=== Vendor logo position ==="
echo "  1) Bottom-right  (default)"
echo "  2) Bottom-left"
echo "  3) Top-right"
echo "  4) Top-left"
echo "  5) Center (below arch logo)"
echo "  6) Center top"
echo "  7) Center bottom"
echo ""
read -rp "Choice [1]: " POS_CHOICE
POS_CHOICE=${POS_CHOICE:-1}

case "$POS_CHOICE" in
    1) VENDOR_POS='vendor.sprite.SetPosition(screen.w - vendor.image.GetWidth() - vendor.padding, screen.h - vendor.image.GetHeight() - vendor.padding, 10);' ;;
    2) VENDOR_POS='vendor.sprite.SetPosition(vendor.padding, screen.h - vendor.image.GetHeight() - vendor.padding, 10);' ;;
    3) VENDOR_POS='vendor.sprite.SetPosition(screen.w - vendor.image.GetWidth() - vendor.padding, vendor.padding, 10);' ;;
    4) VENDOR_POS='vendor.sprite.SetPosition(vendor.padding, vendor.padding, 10);' ;;
    5) VENDOR_POS='vendor.sprite.SetPosition(screen.half.w - vendor.image.GetWidth() / 2, screen.h * 0.55, 10);' ;;
    6) VENDOR_POS='vendor.sprite.SetPosition(screen.half.w - vendor.image.GetWidth() / 2, vendor.padding, 10);' ;;
    7) VENDOR_POS='vendor.sprite.SetPosition(screen.half.w - vendor.image.GetWidth() / 2, screen.h - vendor.image.GetHeight() - vendor.padding, 10);' ;;
    *) VENDOR_POS='vendor.sprite.SetPosition(screen.w - vendor.image.GetWidth() - vendor.padding, screen.h - vendor.image.GetHeight() - vendor.padding, 10);' ;;
esac

# ---- Vendor logo size ----
echo ""
echo "=== Vendor logo size ==="
echo "  1) Small     (7% x 4%)   (default)"
echo "  2) Medium    (10% x 6%)"
echo "  3) Large     (15% x 8%)"
echo "  4) XLarge    (20% x 11%)"
echo ""
read -rp "Choice [1]: " SIZE_CHOICE
SIZE_CHOICE=${SIZE_CHOICE:-1}

case "$SIZE_CHOICE" in
    1) VENDOR_SCALE_W="0.07"; VENDOR_SCALE_H="0.04" ;;
    2) VENDOR_SCALE_W="0.10"; VENDOR_SCALE_H="0.06" ;;
    3) VENDOR_SCALE_W="0.15"; VENDOR_SCALE_H="0.08" ;;
    4) VENDOR_SCALE_W="0.20"; VENDOR_SCALE_H="0.11" ;;
    *) VENDOR_SCALE_W="0.07"; VENDOR_SCALE_H="0.04" ;;
esac

# ---- Extract vendor logo from BGRT ----
mkdir -p "${THEME_DIR}/assets"
cp "${SCRIPT_DIR}/arch-dev.plymouth" "${THEME_DIR}/"
cp "${SCRIPT_DIR}/assets/animation.png" "${THEME_DIR}/assets/"
cp "${SCRIPT_DIR}/assets/background.png" "${THEME_DIR}/assets/"
cp "${SCRIPT_DIR}/assets/progress_bar.png" "${THEME_DIR}/assets/"
cp "${SCRIPT_DIR}/assets/progress_box.png" "${THEME_DIR}/assets/"
cp "${SCRIPT_DIR}/assets/refined-logo.png" "${THEME_DIR}/assets/"
cp "${SCRIPT_DIR}/assets/suspend.png" "${THEME_DIR}/assets/"

VENDOR_OK=0
if [ -f /sys/firmware/acpi/bgrt/image ] && [ -f /sys/firmware/acpi/bgrt/status ]; then
    BGRT_STATUS=$(cat /sys/firmware/acpi/bgrt/status 2>/dev/null || echo 0)
    if [ "$BGRT_STATUS" -eq 1 ] || [ -s /sys/firmware/acpi/bgrt/image ]; then
        cp /sys/firmware/acpi/bgrt/image /tmp/_bgrt.bmp
        if convert /tmp/_bgrt.bmp "${THEME_DIR}/assets/vendor-logo.png" 2>/dev/null; then
            VENDOR_OK=1
            echo "Vendor logo extracted from BGRT"
        fi
        rm -f /tmp/_bgrt.bmp
    fi
fi

if [ "$VENDOR_OK" -eq 0 ]; then
    convert -size 1x1 xc:transparent "${THEME_DIR}/assets/vendor-logo.png" 2>/dev/null \
        || printf '\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1f\x15\xc4\x89\x00\x00\x00\nIDATx\x9cc\x00\x01\x00\x00\x05\x00\x01\r\n\xb4\x00\x00\x00\x00IEND\xaeB`\x82' > "${THEME_DIR}/assets/vendor-logo.png"
    echo "No BGRT found — vendor logo disabled"
fi

# ---- Generate script from template ----
sed \
    -e "s|VENDOR_POS|${VENDOR_POS}|g" \
    -e "s|VENDOR_SCALE_W|${VENDOR_SCALE_W}|g" \
    -e "s|VENDOR_SCALE_H|${VENDOR_SCALE_H}|g" \
    "${TEMPLATE}" > "${THEME_DIR}/assets/arch-dev.script"

# ---- Set theme & rebuild ----
plymouth-set-default-theme "${THEME_NAME}"
echo "Default theme set to ${THEME_NAME}"

mkinitcpio -P
echo "Initramfs rebuilt"

echo ""
echo "Done. Reboot to see the theme."
echo "Config: position=${POS_CHOICE}, scale=${VENDOR_SCALE_W}x${VENDOR_SCALE_H}"
