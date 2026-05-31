'use strict';
'require view';
'require form';
'require uci';

return view.extend({
	load: function() {
		return uci.load('ytunblock');
	},

	addFlag: function(section, name, title, description, def) {
		var o = section.option(form.Flag, name, title, description);
		o.enabled = '1';
		o.disabled = '0';
		o.default = def || '0';
		o.rmempty = false;
		return o;
	},

	addTabFlag: function(section, tab, name, title, description, def) {
		var o = section.taboption(tab, form.Flag, name, title, description);
		o.enabled = '1';
		o.disabled = '0';
		o.default = def || '0';
		o.rmempty = false;
		o.modalonly = true;
		return o;
	},

	renderServiceOptions: function(s) {
		var o;

		this.addFlag(s, 'enabled', _('Включить службу'), _('Полностью включает или отключает обход, не удаляя настройки.'), '1');

		o = s.option(form.ListValue, 'conf_strat', _('Режим настройки'), _('Обычный режим подходит почти всем. Режим аргументов нужен, только если ты хочешь полностью управлять командной строкой вручную.'));
		o.value('ui_flags', _('Обычный'));
		o.value('args', _('Свои аргументы'));
		o.default = 'ui_flags';
		o.rmempty = false;

		o = s.option(form.TextValue, 'args', _('Свои аргументы'));
		o.depends('conf_strat', 'args');
		o.rows = 5;
		o.placeholder = '--queue-num=537 --packet-mark=32768 ...';

		o = s.option(form.Value, 'queue_num', _('Очередь NFQUEUE'));
		o.depends('conf_strat', 'ui_flags');
		o.datatype = 'uinteger';
		o.default = '537';

		o = s.option(form.Value, 'packet_mark', _('Метка пакетов'));
		o.depends('conf_strat', 'ui_flags');
		o.datatype = 'uinteger';
		o.default = '32768';

		o = s.option(form.Value, 'threads', _('Потоки'));
		o.depends('conf_strat', 'ui_flags');
		o.datatype = 'uinteger';
		o.default = '1';

		this.addFlag(s, 'no_gso', _('Отключить GSO'), _('Полезно для Chrome и похожих браузеров, если YouTube открывается частично.'), '1').depends('conf_strat', 'ui_flags');
		this.addFlag(s, 'no_ipv6', _('Не использовать IPv6'), _('Нужно только если IPv6 в сети мешает или не используется.'), '0').depends('conf_strat', 'ui_flags');
		this.addFlag(s, 'silent', _('Тихий режим'), _('Меньше записей в системный журнал.'), '0').depends('conf_strat', 'ui_flags');
		this.addFlag(s, 'trace', _('Подробная отладка'), _('Нужно только для диагностики проблем.'), '0').depends('conf_strat', 'ui_flags');

		o = s.option(form.Value, 'post_args', _('Дополнительные аргументы'));
		o.depends('conf_strat', 'ui_flags');
		o.placeholder = '--foo=bar';
	},

	renderPolicyTabs: function(section) {
		var o;

		section.tab('basic', _('Основное'));
		section.tab('domains', _('Домены'));
		section.tab('transport', _('TCP и QUIC'));
		section.tab('advanced', _('Тонкая настройка'));

		o = section.taboption('basic', form.Value, 'name', _('Название'));
		o.placeholder = _('YouTube');
		o.modalonly = true;

		this.addTabFlag(section, 'basic', 'enabled', _('Использовать этот блок'), _('Можно выключить блок, не удаляя его.'), '1');
		this.addTabFlag(section, 'basic', 'tls_enabled', _('Обрабатывать HTTPS'), _('Обычно должно быть включено.'), '1');
		this.addTabFlag(section, 'basic', 'fake_sni', _('Использовать fake SNI'), _('Помогает в сетях с более жёстким DPI.'), '1');

		o = section.taboption('basic', form.ListValue, 'faking_strategy', _('Стратегия fake SNI'), _('Для большинства сетей лучше оставить `pastseq`.'));
		o.value('pastseq', 'pastseq');
		o.value('randseq', 'randseq');
		o.value('ttl', 'ttl');
		o.value('tcp_check', 'tcp_check');
		o.value('md5sum', 'md5sum');
		o.default = 'pastseq';
		o.modalonly = true;

		o = section.taboption('basic', form.Value, 'faking_ttl', _('TTL для fake-пакетов'));
		o.depends('faking_strategy', 'ttl');
		o.default = '8';
		o.modalonly = true;

		o = section.taboption('basic', form.Value, 'fake_seq_offset', _('Смещение sequence'));
		o.default = '10000';
		o.modalonly = true;

		this.addTabFlag(section, 'domains', 'all_domains', _('Обрабатывать все домены'), _('Обычно не нужно. Лучше оставить только нужные домены.'), '0');

		o = section.taboption('domains', form.DynamicList, 'sni_domains', _('Домены YouTube и API'));
		o.depends('all_domains', '0');
		o.modalonly = true;

		o = section.taboption('domains', form.DynamicList, 'exclude_domains', _('Не трогать эти домены'));
		o.modalonly = true;

		o = section.taboption('domains', form.ListValue, 'sni_detection', _('Как искать SNI'));
		o.value('parse', _('Обычный режим'));
		o.value('brute', _('Глубокий поиск'));
		o.default = 'parse';
		o.modalonly = true;

		o = section.taboption('transport', form.ListValue, 'frag', _('Фрагментация HTTPS'));
		o.value('tcp', _('TCP'));
		o.value('ip', _('IP'));
		o.value('none', _('Не дробить'));
		o.default = 'tcp';
		o.modalonly = true;

		this.addTabFlag(section, 'transport', 'frag_sni_reverse', _('Менять порядок фрагментов'), _('Обычно полезно.'), '1');
		this.addTabFlag(section, 'transport', 'frag_middle_sni', _('Резать в середине SNI'), _('Обычно полезно для YouTube.'), '1');
		this.addTabFlag(section, 'transport', 'frag_sni_faked', _('Заполнять соседние пакеты fake-данными'), _('Более агрессивный режим.'), '0');

		o = section.taboption('transport', form.Value, 'frag_sni_pos', _('Позиция разреза'));
		o.default = '1';
		o.modalonly = true;

		o = section.taboption('transport', form.Value, 'seg2delay', _('Задержка второго сегмента'));
		o.default = '0';
		o.modalonly = true;

		this.addTabFlag(section, 'transport', 'quic_drop', _('Отключать QUIC'), _('Если видео или страницы открываются только частично, это часто помогает.'), '1');

		o = section.taboption('transport', form.ListValue, 'udp_mode', _('Что делать с UDP'));
		o.value('drop', _('Блокировать'));
		o.value('fake', _('Подменять'));
		o.default = 'drop';
		o.modalonly = true;

		o = section.taboption('transport', form.ListValue, 'udp_filter_quic', _('Фильтр QUIC'));
		o.value('disabled', _('Выключен'));
		o.value('parse', _('Только QUIC'));
		o.value('all', _('Все QUIC initial'));
		o.default = 'all';
		o.modalonly = true;

		o = section.taboption('advanced', form.ListValue, 'fake_sni_type', _('Тип fake SNI'));
		o.value('default', _('Стандартный'));
		o.value('random', _('Случайный'));
		o.value('custom', _('Свой payload'));
		o.default = 'default';
		o.modalonly = true;

		o = section.taboption('advanced', form.Value, 'fake_custom_payload', _('Свой payload (hex)'));
		o.depends('fake_sni_type', 'custom');
		o.modalonly = true;

		o = section.taboption('advanced', form.Value, 'fake_sni_seq_len', _('Количество fake-пакетов'));
		o.default = '1';
		o.modalonly = true;

		o = section.taboption('advanced', form.Value, 'fk_winsize', _('Window size'));
		o.default = '0';
		o.modalonly = true;

		this.addTabFlag(section, 'advanced', 'synfake', _('Использовать synfake'), _('Нужно редко, включай только если обычный профиль уже не справляется.'), '0');

		o = section.taboption('advanced', form.Value, 'synfake_len', _('Длина synfake'));
		o.depends('synfake', '1');
		o.default = '0';
		o.modalonly = true;

		o = section.taboption('advanced', form.ListValue, 'udp_faking_strategy', _('Стратегия подмены UDP'));
		o.value('none', _('Без подмены'));
		o.value('checksum', _('Портить checksum'));
		o.value('ttl', _('Ограничивать TTL'));
		o.default = 'none';
		o.modalonly = true;

		o = section.taboption('advanced', form.Value, 'udp_fake_seq_len', _('Количество UDP fake-пакетов'));
		o.default = '6';
		o.modalonly = true;

		o = section.taboption('advanced', form.Value, 'udp_fake_len', _('Размер UDP fake-пакета'));
		o.default = '64';
		o.modalonly = true;

		this.addTabFlag(section, 'advanced', 'udp_stun_filter', _('Фильтровать STUN'), _('Нужно в редких сценариях для голосовых сервисов.'), '0');

		o = section.taboption('advanced', form.DynamicList, 'udp_dport_filter', _('UDP-порты'));
		o.placeholder = '443';
		o.modalonly = true;

		o = section.taboption('advanced', form.Value, 'section_post_args', _('Дополнительные аргументы блока'));
		o.placeholder = '--foo=bar';
		o.modalonly = true;
	},

	render: function() {
		var m = new form.Map('ytunblock', _('YT Unblock — Настройки'),
			_('Здесь можно спокойно настроить обход без ручного редактирования консоли. Для обычного использования достаточно глобальных параметров и одного блока YouTube.'));

		var general = m.section(form.NamedSection, 'ytunblock', 'ytunblock', _('Служба'));
		this.renderServiceOptions(general);

		var policies = m.section(form.GridSection, 'section', _('Блоки правил'), _(
			'Блок описывает, как обрабатывать YouTube-трафик. В большинстве случаев достаточно одного блока. Несколько блоков нужны только для сложных сценариев.'
		));
		policies.anonymous = true;
		policies.addremove = true;
		policies.sortable = true;
		policies.cloneable = true;
		policies.sectiontitle = function(section_id) {
			return uci.get('ytunblock', section_id, 'name') || _('Без названия');
		};

		var enable = policies.option(form.Flag, 'enabled', _('Вкл.'));
		enable.enabled = '1';
		enable.disabled = '0';
		enable.default = '1';
		enable.modalonly = false;
		enable.editable = true;
		enable.rmempty = false;

		this.renderPolicyTabs(policies);
		return m.render();
	}
});
