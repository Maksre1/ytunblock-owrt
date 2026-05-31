'use strict';
'require view';
'require fs';
'require ui';
'require form';

return view.extend({
	load() {
		return Promise.all([
			fs.exec_direct('/usr/libexec/ytunblock/status-json.sh').catch(() => '{}'),
			fs.exec_direct('/usr/bin/nft', ['list', 'chain', 'inet', 'fw4', 'ytunblock']).catch(() =>
				fs.exec_direct('/usr/sbin/nft', ['list', 'chain', 'inet', 'fw4', 'ytunblock']).catch(() => '')),
			fs.exec_direct('/sbin/lsmod').catch(() => fs.exec_direct('/usr/bin/lsmod').catch(() => '')),
		]).then(([json, nft, lsmod]) => ({ json, nft, lsmod }));
	},

	render(data) {
		let info = {};
		try { info = JSON.parse((data.json || '').trim()); } catch (e) {}

		const m = new form.Map('ytunblock', _('YT Unblock — Диагностика'),
			_('Проверка модулей ядра, nftables и состояния службы.'));

		const s = m.section(form.NamedSection, '_diag');
		s.anonymous = true;
		s.render = () => {
			const rows = [
				[_('Служба'), info.status || '—'],
				[_('Версия'), info.version || '—'],
				[_('kmod-nft-queue'), info.kmod_nft_queue || '—'],
				[_('nf_conntrack'), info.kmod_nf_conntrack || '—'],
				[_('Правило nft'), info.nft_rule || '—'],
			];

			const table = E('table', { class: 'table' }, [
				E('tr', { class: 'tr table-titles' }, [
					E('th', { class: 'th' }, _('Параметр')),
					E('th', { class: 'th' }, _('Значение')),
				]),
				...rows.map(r => E('tr', { class: 'tr' }, [
					E('td', { class: 'td' }, r[0]),
					E('td', { class: 'td' }, r[1]),
				])),
			]);

			const mods = (data.lsmod || '').split('\n').filter(l =>
				/nf_queue|nf_conntrack|nft_queue/.test(l)).join('\n') || _('Не найдено');

			return E('div', { class: 'cbi-map' }, [
				E('div', { class: 'cbi-section' }, [
					E('h3', _('Сводка')),
					table,
					E('h3', { style: 'margin-top:1.5rem' }, _('Цепочка nftables (ytunblock)')),
					E('pre', { style: 'overflow:auto;font-size:12px' },
						(data.nft && data.nft.trim()) ? data.nft.trim() : _('Цепочка не найдена. Выполните: /etc/init.d/firewall reload')),
					E('h3', { style: 'margin-top:1.5rem' }, _('Связанные модули (lsmod)')),
					E('pre', { style: 'overflow:auto;font-size:12px' }, mods),
					E('p', { class: 'cbi-section-descr' }, [
						_('Установите зависимости:'),
						' ',
						E('code', {}, 'apk add kmod-nft-queue kmod-nf-conntrack'),
						' ',
						_('или'),
						' ',
						E('code', {}, 'opkg install kmod-nft-queue kmod-nf-conntrack'),
					]),
				]),
			]);
		};

		m.handleSave = m.handleSaveApply = m.handleReset = null;
		return m.render();
	},
});
