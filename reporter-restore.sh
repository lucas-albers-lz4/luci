#!/bin/sh
# Restore stock luci-bwc after the openwrt/luci#9287 overlay.
set -e

bin=/usr/bin/luci-bwc
backup=/root/luci-9287-backup/luci-bwc

[ "$(id -u)" = 0 ] || { echo 'Run as root.'; exit 1; }
[ -f "$backup" ] || { echo "No backup at $backup"; exit 1; }

cp "$backup" "$bin"
chmod 755 "$bin"

if pgrep luci-bwc >/dev/null 2>&1; then
	kill $(pgrep luci-bwc) 2>/dev/null || true
fi

echo "Restored stock luci-bwc from $backup"
echo "Open a realtime graph if you want the stock collector running again."
