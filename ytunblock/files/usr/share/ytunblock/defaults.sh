#!/bin/sh
# Сброс / создание конфигурации по умолчанию

CONFIG="/etc/config/ytunblock"
TEMPLATE="/usr/share/ytunblock/default.config"
MODE="${1:-}"
FORCE=0
MERGE_SECTION=0

[ "$MODE" = "--force" ] && FORCE=1
[ "$MODE" = "--merge-section" ] && MERGE_SECTION=1

if [ "$FORCE" -eq 0 ] && [ "$MERGE_SECTION" -eq 0 ] && [ -n "$(uci -q get ytunblock.ytunblock)" ]; then
	exit 0
fi

if [ "$MERGE_SECTION" -eq 1 ]; then
	uci -q get ytunblock.@section[0] >/dev/null && exit 0
	[ -s "$CONFIG" ] || cp "$TEMPLATE" "$CONFIG"
	uci batch <<'EOI'
add ytunblock section
set ytunblock.@section[-1].name='YouTube'
set ytunblock.@section[-1].enabled='1'
set ytunblock.@section[-1].tls_enabled='1'
set ytunblock.@section[-1].all_domains='0'
set ytunblock.@section[-1].sni_detection='parse'
set ytunblock.@section[-1].fake_sni='1'
set ytunblock.@section[-1].fake_sni_seq_len='1'
set ytunblock.@section[-1].fake_sni_type='default'
set ytunblock.@section[-1].faking_strategy='pastseq'
set ytunblock.@section[-1].faking_ttl='8'
set ytunblock.@section[-1].fake_seq_offset='10000'
set ytunblock.@section[-1].frag='tcp'
set ytunblock.@section[-1].frag_sni_reverse='1'
set ytunblock.@section[-1].frag_sni_faked='0'
set ytunblock.@section[-1].frag_middle_sni='1'
set ytunblock.@section[-1].frag_sni_pos='1'
set ytunblock.@section[-1].seg2delay='0'
set ytunblock.@section[-1].fk_winsize='0'
set ytunblock.@section[-1].synfake='0'
set ytunblock.@section[-1].synfake_len='0'
set ytunblock.@section[-1].quic_drop='1'
set ytunblock.@section[-1].udp_mode='drop'
set ytunblock.@section[-1].udp_faking_strategy='none'
set ytunblock.@section[-1].udp_fake_seq_len='6'
set ytunblock.@section[-1].udp_fake_len='64'
set ytunblock.@section[-1].udp_filter_quic='all'
set ytunblock.@section[-1].udp_stun_filter='0'
set ytunblock.@section[-1].section_post_args=''
add_list ytunblock.@section[-1].exclude_domains='ru'
add_list ytunblock.@section[-1].exclude_domains='gov'
add_list ytunblock.@section[-1].sni_domains='youtube.com'
add_list ytunblock.@section[-1].sni_domains='www.youtube.com'
add_list ytunblock.@section[-1].sni_domains='m.youtube.com'
add_list ytunblock.@section[-1].sni_domains='music.youtube.com'
add_list ytunblock.@section[-1].sni_domains='youtu.be'
add_list ytunblock.@section[-1].sni_domains='youtubei.googleapis.com'
add_list ytunblock.@section[-1].sni_domains='youtube.googleapis.com'
add_list ytunblock.@section[-1].sni_domains='youtube-nocookie.com'
add_list ytunblock.@section[-1].sni_domains='googlevideo.com'
add_list ytunblock.@section[-1].sni_domains='ytimg.com'
add_list ytunblock.@section[-1].sni_domains='i.ytimg.com'
add_list ytunblock.@section[-1].sni_domains='ggpht.com'
add_list ytunblock.@section[-1].sni_domains='yt3.ggpht.com'
add_list ytunblock.@section[-1].sni_domains='yt4.ggpht.com'
add_list ytunblock.@section[-1].sni_domains='googleapis.com'
add_list ytunblock.@section[-1].sni_domains='googleusercontent.com'
add_list ytunblock.@section[-1].sni_domains='gstatic.com'
add_list ytunblock.@section[-1].sni_domains='l.google.com'
add_list ytunblock.@section[-1].sni_domains='play.google.com'
EOI
	uci commit ytunblock
	exit 0
fi

rm -f /tmp/.uci/ytunblock
cp "$TEMPLATE" "$CONFIG"

# Автоматически патчим sing-box для обхода Fake-IP при применении пресета
if [ "$FORCE" -eq 1 ] && [ -f /etc/sing-box/config.json ] && [ -x /usr/bin/jq ]; then
	SB_CONF="/etc/sing-box/config.json"
	SB_TMP="/tmp/sing-box-patched.json"
	if jq 'if (.dns.rules | any(.rule_set == "vpn_exclusion-user-domains-ruleset" and .server == "dns-server")) then . else .dns.rules |= ( [ .[0], .[1], {"action": "route", "server": "dns-server", "rule_set": "vpn_exclusion-user-domains-ruleset"} ] + .[2:] ) end | .dns.rules |= map(if .server == "fakeip-server" and (.rule_set | type) == "array" then .rule_set |= map(select(. != "vpn_exclusion-user-domains-ruleset")) else . end)' "$SB_CONF" > "$SB_TMP" 2>/dev/null; then
		if ! cmp -s "$SB_CONF" "$SB_TMP"; then
			mv "$SB_TMP" "$SB_CONF"
			/etc/init.d/sing-box restart 2>/dev/null || true
		else
			rm -f "$SB_TMP"
		fi
	else
		rm -f "$SB_TMP"
	fi
fi

[ "$FORCE" -eq 1 ] && /etc/init.d/ytunblock restart 2>/dev/null

