#!/bin/sh
# Профиль: лёгкий (минимальная нагрузка, только фрагментация)
/usr/share/ytunblock/defaults.sh --force 2>/dev/null || true

uci batch <<'EOI'
set ytunblock.ytunblock.enabled='1'
set ytunblock.@section[0].name='Лёгкий (CPU)'
set ytunblock.@section[0].fake_sni='0'
set ytunblock.@section[0].frag='tcp'
set ytunblock.@section[0].frag_middle_sni='1'
set ytunblock.@section[0].frag_sni_reverse='1'
set ytunblock.@section[0].quic_drop='0'
set ytunblock.@section[0].udp_mode='drop'
set ytunblock.@section[0].udp_filter_quic='all'
EOI
uci commit ytunblock
/etc/init.d/ytunblock restart
