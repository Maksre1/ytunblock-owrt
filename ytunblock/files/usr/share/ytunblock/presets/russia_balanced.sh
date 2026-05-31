#!/bin/sh
# Профиль: сбалансированный для РФ (фрагментация SNI + fake при необходимости)
/usr/share/ytunblock/defaults.sh --force 2>/dev/null || true

uci batch <<'EOI'
set ytunblock.ytunblock.enabled='1'
set ytunblock.@section[0].name='РФ — сбалансированный'
set ytunblock.@section[0].fake_sni='1'
set ytunblock.@section[0].faking_strategy='pastseq'
set ytunblock.@section[0].frag='tcp'
set ytunblock.@section[0].frag_middle_sni='1'
set ytunblock.@section[0].frag_sni_reverse='1'
set ytunblock.@section[0].seg2delay='1'
set ytunblock.@section[0].udp_filter_quic='all'
set ytunblock.@section[0].udp_mode='fake'
set ytunblock.@section[0].udp_faking_strategy='checksum'
EOI
uci commit ytunblock
/etc/init.d/ytunblock restart
