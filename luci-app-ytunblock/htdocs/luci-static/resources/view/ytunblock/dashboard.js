'use strict';
'require view';
'require poll';
'require fs';
'require ui';
'require uci';
'require form';

function btnSpin(el, on) {
	if (!el) return;
	el.classList.toggle('spinning', on);
	el.classList.toggle('disabled', on);
}

function runAction(act, ev) {
	const t = ev.target;
	btnSpin(t, true);
	const done = () => btnSpin(t, false);

	if (act === 'restart')
		return fs.exec_direct('/etc/init.d/ytunblock', ['restart']).then(done);
	if (act === 'fw')
		return fs.exec_direct('/etc/init.d/firewall', ['reload']).then(done);
	if (act === 'start')
		return fs.exec_direct('/etc/init.d/ytunblock', ['start']).then(done);
	if (act === 'stop')
		return fs.exec_direct('/etc/init.d/ytunblock', ['stop']).then(done);
	if (act === 'enable')
		return fs.exec_direct('/etc/init.d/ytunblock', ['enable']).then(done);
	if (act === 'disable')
		return fs.exec_direct('/etc/init.d/ytunblock', ['disable']).then(done);
	if (act === 'reset')
		return fs.exec_direct('/usr/share/ytunblock/defaults.sh', ['--force'])
			.then(() => fs.exec_direct('/etc/init.d/ytunblock', ['restart']))
			.then(done);
	if (act.startsWith('preset:'))
		return fs.exec_direct('/usr/libexec/ytunblock/apply-preset.sh', [act.split(':')[1]])
			.then(done);
	done();
}

function statusBadge(st) {
	const map = {
		running: ['label success', _('Running')],
		inactive: ['label', _('Stopped')],
	};
	const m = map[st] || ['label warning', st];
	return E('span', { class: m[0] }, [m[1]]);
}

function depBadge(ok) {
	return E('span', { class: ok ? 'label success' : 'label important' },
		[ok ? _('OK') : _('Missing')]);
}

return view.extend({
	load() {
		return uci.load('ytunblock');
	},

	render() {
		const m = new form.Map('ytunblock', _('YT Unblock'),
			_('Обход DPI для YouTube. Основано на <a href="https://github.com/Waujito/youtubeUnblock" target="_blank">youtubeUnblock</a>.'));

		const s = m.section(form.NamedSection, '_dash');
		s.anonymous = true;
		s.render = () => E('div', { class: 'cbi-section' }, [
			E('h3', _('Статус')),
			E('div', { class: 'cbi-value' }, [
				E('label', { class: 'cbi-value-title' }, _('Служба')),
				E('div', { class: 'cbi-value-field', id: 'ytb_status' }, E('em', _('Loading…')))
			]),
			E('div', { class: 'cbi-value' }, [
				E('label', { class: 'cbi-value-title' }, _('Версия')),
				E('div', { class: 'cbi-value-field', id: 'ytb_version' }, '—')
			]),
			E('div', { class: 'cbi-value' }, [
				E('label', { class: 'cbi-value-title' }, _('Автозапуск')),
				E('div', { class: 'cbi-value-field', id: 'ytb_autostart' }, '—')
			]),
			E('div', { class: 'cbi-value' }, [
				E('label', { class: 'cbi-value-title' }, _('PID')),
				E('div', { class: 'cbi-value-field', id: 'ytb_pid' }, '—')
			]),
			E('h3', { style: 'margin-top:1.5rem' }, _('Зависимости')),
			E('div', { class: 'cbi-value' }, [
				E('label', { class: 'cbi-value-title' }, 'kmod-nft-queue'),
				E('div', { class: 'cbi-value-field', id: 'ytb_kmod_queue' }, '—')
			]),
			E('div', { class: 'cbi-value' }, [
				E('label', { class: 'cbi-value-title' }, 'nf_conntrack'),
				E('div', { class: 'cbi-value-field', id: 'ytb_kmod_ct' }, '—')
			]),
			E('div', { class: 'cbi-value' }, [
				E('label', { class: 'cbi-value-title' }, _('nftables')),
				E('div', { class: 'cbi-value-field', id: 'ytb_nft' }, '—')
			]),
			E('h3', { style: 'margin-top:1.5rem' }, _('Быстрые профили')),
			E('p', { class: 'cbi-section-descr' },
				_('Профили перезаписывают текущую конфигурацию и перезапускают службу.')),
			E('div', { class: 'right' }, [
				E('button', { class: 'btn cbi-button', click: e => runAction('preset:default', e) },
					[_('По умолчанию')]),
				' ',
				E('button', { class: 'btn cbi-button', click: e => runAction('preset:lite', e) },
					[_('Лёгкий')]),
				' ',
				E('button', { class: 'btn cbi-button-apply', click: e => runAction('preset:russia_balanced', e) },
					[_('РФ — сбалансированный')]),
				' ',
				E('button', { class: 'btn cbi-button-apply', click: e => runAction('preset:russia_aggressive', e) },
					[_('РФ — агрессивный')]),
			]),
			E('h3', { style: 'margin-top:1.5rem' }, _('Управление')),
			E('div', { class: 'right' }, [
				E('button', { class: 'btn cbi-button-positive', id: 'btn_start', click: e => runAction('start', e) }, [_('Старт')]),
				' ',
				E('button', { class: 'btn cbi-button-negative', id: 'btn_stop', click: e => runAction('stop', e) }, [_('Стоп')]),
				' ',
				E('button', { class: 'btn cbi-button-apply', click: e => runAction('restart', e) }, [_('Перезапуск')]),
				' ',
				E('button', { class: 'btn cbi-button', id: 'btn_autostart', click: e => runAction('enable', e) }, [_('Автозапуск')]),
				' ',
				E('button', { class: 'btn cbi-button', click: e => runAction('fw', e) }, [_('Перезагрузить firewall')]),
				' ',
				E('button', { class: 'btn cbi-button-negative', click: e => runAction('reset', e) }, [_('Сброс конфигурации')]),
			]),
			E('h3', { style: 'margin-top:1.5rem' }, _('Журнал')),
			E('textarea', {
				id: 'ytb_log',
				readonly: 'readonly',
				style: 'width:100%;font-family:monospace;font-size:12px',
				rows: 18
			})
		]);

		poll.add(() => {
			return fs.exec_direct('/usr/libexec/ytunblock/status-json.sh').then(raw => {
				let d = {};
				try { d = JSON.parse(raw.trim()); } catch (e) { return; }

				const st = document.getElementById('ytb_status');
				if (st) st.replaceChildren(statusBadge(d.status));

				const ver = document.getElementById('ytb_version');
				if (ver) ver.textContent = d.version || '—';

				const as = document.getElementById('ytb_autostart');
				if (as) as.textContent = d.autostart === 'enabled' ? _('Enabled') : _('Disabled');

				const pid = document.getElementById('ytb_pid');
				if (pid) pid.textContent = d.pid || '—';

				const kq = document.getElementById('ytb_kmod_queue');
				if (kq) kq.replaceChildren(depBadge(d.kmod_nft_queue === 'loaded'));

				const kc = document.getElementById('ytb_kmod_ct');
				if (kc) kc.replaceChildren(depBadge(d.kmod_nf_conntrack === 'loaded'));

				const nft = document.getElementById('ytb_nft');
				if (nft) {
					const ok = d.nft_rule === 'ok' || d.nft_rule === 'legacy';
					nft.replaceChildren(depBadge(ok));
					if (d.nft_rule === 'legacy')
						nft.appendChild(document.createTextNode(' (youtubeUnblock)'));
				}

				const btnAs = document.getElementById('btn_autostart');
				if (btnAs) {
					btnAs.textContent = d.autostart === 'enabled' ? _('Отключить автозапуск') : _('Включить автозапуск');
					btnAs.onclick = e => runAction(d.autostart === 'enabled' ? 'disable' : 'enable', e);
				}
			}).then(() => {
				return fs.exec_direct('/sbin/logread', ['-e', 'ytunblock', '-l', '150'])
					.catch(() => fs.exec_direct('/sbin/logread', ['-e', 'youtubeUnblock', '-l', '150']))
					.then(res => {
						const log = document.getElementById('ytb_log');
						if (log) {
							log.value = (res && res.trim()) ? res.trim() : _('Записей пока нет');
							log.scrollTop = log.scrollHeight;
						}
					});
			});
		}, 3);

		m.handleSave = m.handleSaveApply = m.handleReset = null;
		return m.render();
	}
});
