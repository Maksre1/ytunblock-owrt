#!/bin/sh
# Сброс / создание конфигурации по умолчанию

FORCE=0
[ "$1" = "--force" ] && FORCE=1

if [ "$FORCE" -eq 0 ] && [ -n "$(uci -q get ytunblock.ytunblock)" ]; then
	exit 0
fi

while uci -q delete ytunblock.@section[0]; do :; done
uci -q delete ytunblock.ytunblock 2>/dev/null

touch /etc/config/ytunblock
uci batch <<'EOI'
set ytunblock.ytunblock=ytunblock
set ytunblock.ytunblock.enabled='1'
set ytunblock.ytunblock.conf_strat='ui_flags'
set ytunblock.ytunblock.packet_mark='32768'
set ytunblock.ytunblock.queue_num='537'

add ytunblock section
set ytunblock.@section[0].name='YouTube (по умолчанию)'
set ytunblock.@section[0].enabled='1'
set ytunblock.@section[0].tls_enabled='1'
set ytunblock.@section[0].fake_sni='0'
set ytunblock.@section[0].faking_strategy='pastseq'
set ytunblock.@section[0].fake_sni_seq_len='1'
set ytunblock.@section[0].fake_sni_type='default'
set ytunblock.@section[0].frag='tcp'
set ytunblock.@section[0].frag_sni_reverse='1'
set ytunblock.@section[0].frag_sni_faked='0'
set ytunblock.@section[0].frag_middle_sni='1'
set ytunblock.@section[0].frag_sni_pos='1'
set ytunblock.@section[0].seg2delay='0'
set ytunblock.@section[0].fk_winsize='0'
set ytunblock.@section[0].synfake='0'
set ytunblock.@section[0].sni_detection='parse'
set ytunblock.@section[0].all_domains='0'
add_list ytunblock.@section[0].sni_domains='googlevideo.com'
add_list ytunblock.@section[0].sni_domains='ggpht.com'
add_list ytunblock.@section[0].sni_domains='ytimg.com'
add_list ytunblock.@section[0].sni_domains='youtube.com'
add_list ytunblock.@section[0].sni_domains='play.google.com'
add_list ytunblock.@section[0].sni_domains='youtu.be'
add_list ytunblock.@section[0].sni_domains='googleapis.com'
add_list ytunblock.@section[0].sni_domains='googleusercontent.com'
add_list ytunblock.@section[0].sni_domains='gstatic.com'
add_list ytunblock.@section[0].sni_domains='l.google.com'
set ytunblock.@section[0].quic_drop='0'
set ytunblock.@section[0].udp_mode='fake'
set ytunblock.@section[0].udp_fake_seq_len='6'
set ytunblock.@section[0].udp_fake_len='64'
set ytunblock.@section[0].udp_filter_quic='disabled'
set ytunblock.@section[0].udp_faking_strategy='none'
EOI
uci commit ytunblock

[ "$FORCE" -eq 1 ] && /etc/init.d/ytunblock restart 2>/dev/null
