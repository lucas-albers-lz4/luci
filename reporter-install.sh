#!/bin/sh
# Overlay a patched luci-bwc for openwrt/luci#9287.
# Built with ghcr.io/openwrt/sdk:mediatek-filogic-25.12.6 (r33311-981c978eff).
# aarch64 / mediatek/filogic only. Not a package. Sysupgrade restores stock.
set -e

bin=/usr/bin/luci-bwc
backup=/root/luci-9287-backup
tmp=/tmp/luci-bwc-9287
# Filled after the binary is published. Do not run with this placeholder.
url='https://raw.githubusercontent.com/lucas-albers-lz4/luci/8f1a2159048a569733d8716f23f52472bcfdb340/luci-bwc'
sha='47c70244a83f8fe7c536014a141f0a5c1c84ab095f282a8d5a0bc009a3fb3056'

[ "$(id -u)" = 0 ] || { echo 'Run as root.'; exit 1; }
[ -f "$bin" ] || { echo "Missing $bin"; exit 1; }
[ ! -e "$backup" ] || { echo "Backup already exists: $backup"; echo 'Restore that copy or move it aside before retrying.'; exit 1; }

machine=$(uname -m)
[ "$machine" = aarch64 ] || {
	echo "This overlay is aarch64 only (mediatek/filogic). This device is $machine."
	exit 1
}

if [ -f /etc/openwrt_release ]; then
	# shellcheck disable=SC1091
	. /etc/openwrt_release
	echo "Device: ${DISTRIB_DESCRIPTION:-unknown} target=${DISTRIB_TARGET:-unknown}"
	case "${DISTRIB_TARGET:-}" in
	mediatek/filogic) ;;
	*)
		echo "WARNING: this binary was built for mediatek/filogic. Target is ${DISTRIB_TARGET:-unknown}."
		;;
	esac
	case "${DISTRIB_RELEASE:-}" in
	25.12.6) ;;
	25.12*)
		echo "WARNING: built against 25.12.6 SDK; this device is ${DISTRIB_RELEASE}."
		;;
	*)
		echo "WARNING: built against OpenWrt 25.12.6; this device is ${DISTRIB_RELEASE:-unknown}."
		;;
	esac
fi

case "$url" in
__DOWNLOAD_URL__|'')
	echo 'Install script has no download URL yet.'
	exit 1
	;;
esac

command -v wget >/dev/null 2>&1 || { echo 'wget is required.'; exit 1; }
command -v sha256sum >/dev/null 2>&1 || { echo 'sha256sum is required.'; exit 1; }

wget -O "$tmp" "$url"
echo "$sha  $tmp" | sha256sum -c -

mkdir "$backup"
if ! cp "$bin" "$backup/luci-bwc"; then
	echo "Backup copy failed; inspect $backup"
	exit 1
fi

if ! cp "$tmp" "$bin"; then
	echo "Install failed; restore the original from $backup/luci-bwc"
	exit 1
fi
chmod 755 "$bin"

# Collector restarts when a realtime graph is opened.
if pgrep luci-bwc >/dev/null 2>&1; then
	kill $(pgrep luci-bwc) 2>/dev/null || true
fi

echo "Installed patched luci-bwc. Backup: $backup/luci-bwc"
echo "Open Status → Realtime Graphs, wait a few seconds, then: ls /var/lib/luci-bwc/radio/"
echo "Restore: sh /root/luci-9287-restore.sh   (or cp $backup/luci-bwc $bin)"
