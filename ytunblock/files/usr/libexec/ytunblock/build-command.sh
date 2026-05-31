#!/bin/sh

PROG="/usr/bin/youtubeUnblock"

append_kv() {
	local name="$1"
	local value="$2"
	[ -n "$value" ] || return 0
	ARGS="$ARGS --${name//_/-}=$value"
}

append_flag() {
	local name="$1"
	ARGS="$ARGS --${name//_/-}"
}

append_value() {
	local section="$1"
	local name="$2"
	local value
	config_get value "$section" "$name"
	append_kv "$name" "$value"
}

append_bool_value() {
	local section="$1"
	local name="$2"
	local value
	config_get_bool value "$section" "$name" 0
	append_kv "$name" "$value"
}

append_if_enabled() {
	local section="$1"
	local name="$2"
	local value
	config_get_bool value "$section" "$name" 0
	[ "$value" -gt 0 ] && append_flag "$name"
}

append_list_csv() {
	local section="$1"
	local name="$2"
	local result=""

	_collect() {
		result="${result}$1,"
	}

	config_list_foreach "$section" "$name" _collect
	result="${result%,}"
	append_kv "$name" "$result"
}

build_section() {
	local section="$1"
	local enabled tls_enabled all_domains value

	config_get_bool enabled "$section" enabled 0
	[ "$enabled" -gt 0 ] || return 0

	[ "$SECTION_COUNT" -gt 0 ] && append_flag "fbegin"
	SECTION_COUNT=$((SECTION_COUNT + 1))

	config_get_bool tls_enabled "$section" tls_enabled 1
	append_kv "tls" "$([ "$tls_enabled" -gt 0 ] && echo enabled || echo disabled)"

	config_get_bool all_domains "$section" all_domains 0
	if [ "$all_domains" -gt 0 ]; then
		append_kv "sni_domains" "all"
	else
		append_list_csv "$section" "sni_domains"
	fi

	append_value "$section" "sni_detection"
	append_list_csv "$section" "exclude_domains"

	append_bool_value "$section" "fake_sni"
	append_value "$section" "fake_sni_seq_len"
	append_value "$section" "fake_sni_type"
	append_value "$section" "fake_custom_payload"
	append_value "$section" "faking_strategy"
	append_value "$section" "faking_ttl"
	append_value "$section" "fake_seq_offset"

	append_value "$section" "frag"
	append_bool_value "$section" "frag_sni_reverse"
	append_bool_value "$section" "frag_sni_faked"
	append_bool_value "$section" "frag_middle_sni"
	append_value "$section" "frag_sni_pos"
	append_value "$section" "seg2delay"
	append_value "$section" "fk_winsize"

	append_bool_value "$section" "synfake"
	append_value "$section" "synfake_len"

	append_if_enabled "$section" "quic_drop"
	append_value "$section" "udp_mode"
	append_value "$section" "udp_faking_strategy"
	append_value "$section" "udp_fake_seq_len"
	append_value "$section" "udp_fake_len"
	append_value "$section" "udp_filter_quic"
	append_if_enabled "$section" "udp_stun_filter"
	append_list_csv "$section" "udp_dport_filter"

	config_get value "$section" "section_post_args"
	[ -n "$value" ] && ARGS="$ARGS $value"
}

. /lib/functions.sh
config_load ytunblock

ARGS=""
SECTION_COUNT=0

config_get mode ytunblock conf_strat "ui_flags"
if [ "$mode" = "args" ]; then
	config_get raw ytunblock args
	printf '%s %s\n' "$PROG" "$raw"
	exit 0
fi

append_value ytunblock queue_num
append_value ytunblock packet_mark
append_value ytunblock threads
append_if_enabled ytunblock no_gso
append_if_enabled ytunblock no_ipv6
append_if_enabled ytunblock silent
append_if_enabled ytunblock trace
config_foreach build_section section
config_get post ytunblock post_args
[ -n "$post" ] && ARGS="$ARGS $post"

printf '%s %s\n' "$PROG" "${ARGS# }"
