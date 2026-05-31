#!/bin/sh
# Профиль: агрессивный (сильный DPI, выше нагрузка на CPU)
/usr/share/ytunblock/defaults.sh --force 2>/dev/null || true

uci batch <<'EOI'
set ytunblock.ytunblock.enabled='1'
set ytunblock.@section[0].name='РФ — агрессивный'
set ytunblock.@section[0].fake_sni='1'
set ytunblock.@section[0].faking_strategy='ttl'
set ytunblock.@section[0].faking_ttl='8'
set ytunblock.@section[0].frag='tcp'
set ytunblock.@section[0].frag_middle_sni='1'
set ytunblock.@section[0].frag_sni_faked='1'
set ytunblock.@section[0].frag_sni_reverse='1'
set ytunblock.@section[0].seg2delay='2'
set ytunblock.@section[0].quic_drop='1'
set ytunblock.@section[0].synfake='0'
EOI
uci commit ytunblock
/etc/init.d/ytunblock restart
