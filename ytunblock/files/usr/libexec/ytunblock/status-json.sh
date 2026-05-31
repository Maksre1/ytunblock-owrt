#!/bin/sh
# JSON-статус для LuCI / rpcd

json_escape() {
	printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

status="inactive"
pid=""
version=""

[ -x /usr/bin/youtubeUnblock ] && version="$(/usr/bin/youtubeUnblock --version 2>/dev/null | head -1)"
pid="$(pidof youtubeUnblock 2>/dev/null)"
[ -n "$pid" ] && status="running"

autostart="disabled"
/etc/init.d/ytunblock enabled >/dev/null 2>&1 && autostart="enabled"

uci_enabled="$(uci -q get ytunblock.ytunblock.enabled 2>/dev/null)"
[ -z "$uci_enabled" ] && uci_enabled="1"

# Проверка kernel modules
check_kmod() {
	lsmod 2>/dev/null | grep -q "^${1}\s" && echo "loaded" || \
		[ -d "/sys/module/${1}" ] && echo "loaded" || echo "missing"
}

nft_queue="$(check_kmod nf_queue)"
nf_conntrack="$(check_kmod nf_conntrack)"

nft_rule="missing"
if nft list chain inet fw4 ytunblock >/dev/null 2>&1; then
	nft_rule="ok"
elif nft list chain inet fw4 youtubeUnblock >/dev/null 2>&1; then
	nft_rule="legacy"
fi

printf '{'
printf '"status":"%s",' "$(json_escape "$status")"
printf '"pid":"%s",' "$(json_escape "$pid")"
printf '"version":"%s",' "$(json_escape "$version")"
printf '"autostart":"%s",' "$(json_escape "$autostart")"
printf '"uci_enabled":"%s",' "$(json_escape "$uci_enabled")"
printf '"kmod_nft_queue":"%s",' "$(json_escape "$nft_queue")"
printf '"kmod_nf_conntrack":"%s",' "$(json_escape "$nf_conntrack")"
printf '"nft_rule":"%s"' "$(json_escape "$nft_rule")"
printf '}\n'
