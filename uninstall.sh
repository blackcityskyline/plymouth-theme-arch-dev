#!/bin/bash
set -euo pipefail

THEME_NAME="arch-dev"
THEME_DIR="/usr/share/plymouth/themes/${THEME_NAME}"

if [ "$(id -u)" -ne 0 ]; then
    echo "Run as root"
    exit 1
fi

echo "Uninstalling ${THEME_NAME} theme..."

rm -rf "${THEME_DIR}"

if [ "$(plymouth-set-default-theme)" = "${THEME_NAME}" ]; then
    plymouth-set-default-theme bgrt
    echo "Default theme reset to bgrt"
fi

mkinitcpio -P
echo "Initramfs rebuilt"

echo "Done."
