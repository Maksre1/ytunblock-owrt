#!/bin/sh

CONFIG="/etc/config/ytunblock"
TEMPLATE="/usr/share/ytunblock/default.config"

copy_from_legacy() {
	[ -s "$CONFIG" ] && return 0
	[ -s /etc/config/youtubeUnblock ] || return 0

	cp /etc/config/youtubeUnblock "$CONFIG" || return 1
	sed -i \
		-e "s/^config youtubeUnblock/config ytunblock/" \
		-e "s/^config main/config ytunblock/" \
		-e "s/^config youtubeUnblock '\([^']*\)'/config ytunblock '\1'/" \
		"$CONFIG"
}

ensure_base_file() {
	[ -s "$CONFIG" ] && return 0
	[ -s "$TEMPLATE" ] || return 1
	cp "$TEMPLATE" "$CONFIG"
}

ensure_main_option() {
	local option="$1"
	local value

	value="$(uci -q get "ytunblock.ytunblock.$option")"
	[ -n "$value" ] && return 0
	value="$(uci -q get "ytunblock.@ytunblock[0].$option")"
	[ -n "$value" ] && uci -q set "ytunblock.ytunblock.$option=$value" && return 0
	value="$(uci -q get "ytunblock.@youtubeUnblock[0].$option")"
	[ -n "$value" ] && uci -q set "ytunblock.ytunblock.$option=$value" && return 0
	value="$(uci -q get "ytunblock.@main[0].$option")"
	[ -n "$value" ] && uci -q set "ytunblock.ytunblock.$option=$value"
}

ensure_named_main() {
	uci -q get ytunblock.ytunblock >/dev/null && return 0

	local fallback
	fallback="$(uci -q get ytunblock.@ytunblock[0])"
	[ -z "$fallback" ] && fallback="$(uci -q get ytunblock.@youtubeUnblock[0])"
	[ -z "$fallback" ] && fallback="$(uci -q get ytunblock.@main[0])"

	[ -n "$fallback" ] || {
		uci -q set ytunblock.ytunblock=ytunblock
		return 0
	}

	uci -q rename "ytunblock.$fallback=ytunblock"
	uci -q set ytunblock.ytunblock=ytunblock
}

ensure_default_section() {
	uci -q get ytunblock.@section[0] >/dev/null && return 0
	/usr/share/ytunblock/defaults.sh --merge-section >/dev/null 2>&1 || return 1
}

set_default_if_missing() {
	local key="$1"
	local value="$2"

	[ -n "$(uci -q get "$key")" ] && return 0
	uci -q set "$key=$value"
}

set_list_if_missing() {
	local key="$1"
	local value="$2"

	uci -q show "$key" 2>/dev/null | grep -Fqs "'$value'" && return 0
	uci -q add_list "$key=$value"
}

main() {
	copy_from_legacy
	ensure_base_file || exit 1
	ensure_named_main

	for opt in enabled conf_strat queue_num packet_mark threads no_gso no_ipv6 silent trace post_args schema_version; do
		ensure_main_option "$opt"
	done

	set_default_if_missing ytunblock.ytunblock.enabled '1'
	set_default_if_missing ytunblock.ytunblock.conf_strat 'ui_flags'
	set_default_if_missing ytunblock.ytunblock.queue_num '537'
	set_default_if_missing ytunblock.ytunblock.packet_mark '32768'
	set_default_if_missing ytunblock.ytunblock.threads '1'
	set_default_if_missing ytunblock.ytunblock.no_gso '1'
	set_default_if_missing ytunblock.ytunblock.no_ipv6 '0'
	set_default_if_missing ytunblock.ytunblock.silent '0'
	set_default_if_missing ytunblock.ytunblock.trace '0'
	set_default_if_missing ytunblock.ytunblock.post_args ''
	set_default_if_missing ytunblock.ytunblock.schema_version '2'

	ensure_default_section || exit 1

	set_default_if_missing ytunblock.@section[0].name 'YouTube'
	set_default_if_missing ytunblock.@section[0].enabled '1'
	set_default_if_missing ytunblock.@section[0].tls_enabled '1'
	set_default_if_missing ytunblock.@section[0].all_domains '0'
	set_default_if_missing ytunblock.@section[0].sni_detection 'parse'
	set_default_if_missing ytunblock.@section[0].fake_sni '1'
	set_default_if_missing ytunblock.@section[0].fake_sni_seq_len '1'
	set_default_if_missing ytunblock.@section[0].fake_sni_type 'default'
	set_default_if_missing ytunblock.@section[0].faking_strategy 'pastseq'
	set_default_if_missing ytunblock.@section[0].faking_ttl '8'
	set_default_if_missing ytunblock.@section[0].fake_seq_offset '10000'
	set_default_if_missing ytunblock.@section[0].frag 'tcp'
	set_default_if_missing ytunblock.@section[0].frag_sni_reverse '1'
	set_default_if_missing ytunblock.@section[0].frag_sni_faked '0'
	set_default_if_missing ytunblock.@section[0].frag_middle_sni '1'
	set_default_if_missing ytunblock.@section[0].frag_sni_pos '1'
	set_default_if_missing ytunblock.@section[0].seg2delay '0'
	set_default_if_missing ytunblock.@section[0].fk_winsize '0'
	set_default_if_missing ytunblock.@section[0].synfake '0'
	set_default_if_missing ytunblock.@section[0].synfake_len '0'
	set_default_if_missing ytunblock.@section[0].quic_drop '1'
	set_default_if_missing ytunblock.@section[0].udp_mode 'drop'
	set_default_if_missing ytunblock.@section[0].udp_faking_strategy 'none'
	set_default_if_missing ytunblock.@section[0].udp_fake_seq_len '6'
	set_default_if_missing ytunblock.@section[0].udp_fake_len '64'
	set_default_if_missing ytunblock.@section[0].udp_filter_quic 'all'
	set_default_if_missing ytunblock.@section[0].udp_stun_filter '0'
	set_default_if_missing ytunblock.@section[0].section_post_args ''

	for item in ru gov; do
		set_list_if_missing ytunblock.@section[0].exclude_domains "$item"
	done

	for item in \
		youtube.com \
		www.youtube.com \
		m.youtube.com \
		music.youtube.com \
		youtu.be \
		youtubei.googleapis.com \
		youtube.googleapis.com \
		youtube-nocookie.com \
		googlevideo.com \
		ytimg.com \
		i.ytimg.com \
		ggpht.com \
		yt3.ggpht.com \
		yt4.ggpht.com \
		googleapis.com \
		googleusercontent.com \
		gstatic.com \
		l.google.com \
		play.google.com
	do
		set_list_if_missing ytunblock.@section[0].sni_domains "$item"
	done

	uci commit ytunblock
}

main "$@"
