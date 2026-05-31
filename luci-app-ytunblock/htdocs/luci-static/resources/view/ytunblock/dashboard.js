'use strict';
'require view';
'require poll';
'require fs';
'require form';

function setBusy(node, on) {
	if (!node)
		return;
	node.classList.toggle('spinning', on);
	node.classList.toggle('disabled', on);
}

function badge(kind, text) {
	return E('span', { class: 'label ' + kind }, [text]);
}

function runCommand(cmd, args, button) {
	setBusy(button, true);
	return fs.exec_direct(cmd, args || []).finally(function() {
		setBusy(button, false);
	});
}

return view.extend({
	render: function() {
		var m = new form.Map('ytunblock', _('YT Unblock'),
			_('Спокойная настройка обхода YouTube для OpenWrt. Здесь можно быстро проверить состояние службы, применить готовый профиль и посмотреть журнал без ручной работы в консоли.'));

		var s = m.section(form.NamedSection, '_dashboard');
		s.anonymous = true;
		s.render = function() {
			return E('div', { class: 'cbi-section' }, [
				E('div', { class: 'cbi-section-descr' }, _(
					'Если YouTube открывается, но часть видео или каналов не загружается, начните с профиля «РФ — сбалансированный». Если всё уже работает стабильно, лучше не крутить лишние параметры.'
				)),

				E('h3', _('Сейчас')),
				E('div', { class: 'cbi-value' }, [
					E('label', { class: 'cbi-value-title' }, _('Служба')),
					E('div', { class: 'cbi-value-field', id: 'yt-status' }, E('em', _('Проверяю…')))
				]),
				E('div', { class: 'cbi-value' }, [
					E('label', { class: 'cbi-value-title' }, _('Автозапуск')),
					E('div', { class: 'cbi-value-field', id: 'yt-autostart' }, '—')
				]),
				E('div', { class: 'cbi-value' }, [
					E('label', { class: 'cbi-value-title' }, _('Версия')),
					E('div', { class: 'cbi-value-field', id: 'yt-version' }, '—')
				]),
				E('div', { class: 'cbi-value' }, [
					E('label', { class: 'cbi-value-title' }, _('Правило firewall')),
					E('div', { class: 'cbi-value-field', id: 'yt-firewall' }, '—')
				]),

				E('h3', { style: 'margin-top:1.5rem' }, _('Быстрые действия')),
				E('div', { class: 'right' }, [
					E('button', {
						class: 'btn cbi-button cbi-button-positive',
						id: 'yt-start-stop',
						click: function(ev) {
							var mode = ev.currentTarget.getAttribute('data-mode') || 'start';
							return runCommand('/etc/init.d/ytunblock', [mode], ev.currentTarget);
						}
					}, _('Запустить')),
					' ',
					E('button', {
						class: 'btn cbi-button cbi-button-apply',
						click: function(ev) {
							return runCommand('/etc/init.d/ytunblock', ['restart'], ev.currentTarget);
						}
					}, _('Перезапустить')),
					' ',
					E('button', {
						class: 'btn cbi-button',
						id: 'yt-autostart-btn',
						click: function(ev) {
							var mode = ev.currentTarget.getAttribute('data-mode') || 'enable';
							return runCommand('/etc/init.d/ytunblock', [mode], ev.currentTarget);
						}
					}, _('Автозапуск')),
					' ',
					E('button', {
						class: 'btn cbi-button',
						click: function(ev) {
							return runCommand('/etc/init.d/firewall', ['reload'], ev.currentTarget);
						}
					}, _('Обновить firewall'))
				]),

				E('h3', { style: 'margin-top:1.5rem' }, _('Готовые профили')),
				E('div', { class: 'cbi-section-descr' }, _(
					'Профиль меняет конфигурацию и сразу перезапускает службу. Для большинства сетей достаточно «По умолчанию» или «РФ — сбалансированный».'
				)),
				E('div', { class: 'right' }, [
					E('button', {
						class: 'btn cbi-button',
						click: function(ev) {
							return runCommand('/usr/libexec/ytunblock/apply-preset.sh', ['default'], ev.currentTarget);
						}
					}, _('По умолчанию')),
					' ',
					E('button', {
						class: 'btn cbi-button',
						click: function(ev) {
							return runCommand('/usr/libexec/ytunblock/apply-preset.sh', ['lite'], ev.currentTarget);
						}
					}, _('Лёгкий')),
					' ',
					E('button', {
						class: 'btn cbi-button-apply',
						click: function(ev) {
							return runCommand('/usr/libexec/ytunblock/apply-preset.sh', ['russia_balanced'], ev.currentTarget);
						}
					}, _('РФ — сбалансированный')),
					' ',
					E('button', {
						class: 'btn cbi-button-apply',
						click: function(ev) {
							return runCommand('/usr/libexec/ytunblock/apply-preset.sh', ['russia_balanced_discord'], ev.currentTarget);
						}
					}, _('РФ + Discord')),
					' ',
					E('button', {
						class: 'btn cbi-button-apply',
						click: function(ev) {
							return runCommand('/usr/libexec/ytunblock/apply-preset.sh', ['russia_aggressive'], ev.currentTarget);
						}
					}, _('РФ — агрессивный'))
				]),

				E('h3', { style: 'margin-top:1.5rem' }, _('Автоматический подбор настроек')),
				E('div', { class: 'cbi-section-descr' }, _(
					'Запускает проверку различных параметров фрагментации и подмены SNI. Находит рабочую конфигурацию для вашей сети и применяет её автоматически. Процесс занимает около 30 секунд.'
				)),
				E('div', { class: 'right', style: 'margin-bottom:1rem' }, [
					E('button', {
						class: 'btn cbi-button cbi-button-action',
						id: 'yt-scan-btn',
						click: function(ev) {
							var btn = ev.currentTarget;
							setBusy(btn, true);
							var logArea = document.getElementById('yt-scan-log');
							if (logArea) logArea.value = _('Запуск сканирования...\n');
							
							var timer = setInterval(function() {
								fs.exec_direct('/bin/cat', ['/var/log/ytunblock-scan.log']).then(function(logs) {
									if (logArea && logs) {
										logArea.value = logs;
										logArea.scrollTop = logArea.scrollHeight;
									}
								}).catch(function() {});
							}, 1000);
							
							return fs.exec_direct('/usr/libexec/ytunblock/scan-strategies.sh').then(function(res) {
								return fs.exec_direct('/bin/cat', ['/var/log/ytunblock-scan.log']).then(function(logs) {
									if (logArea) {
										logArea.value = logs + '\n' + _('Подбор завершен!');
										logArea.scrollTop = logArea.scrollHeight;
									}
								});
							}).catch(function(err) {
								if (logArea) logArea.value += '\n' + _('Произошла ошибка во время сканирования: ') + err;
							}).finally(function() {
								clearInterval(timer);
								setBusy(btn, false);
							});
						}
					}, _('Начать подбор настроек'))
				]),
				E('textarea', {
					id: 'yt-scan-log',
					readonly: 'readonly',
					rows: 10,
					wrap: 'off',
					placeholder: _('Здесь будет отображаться процесс тестирования стратегий...'),
					style: 'width:100%;font-family:monospace;background:#f5f5f5;border:1px solid #ddd;padding:5px;'
				}),

				E('h3', { style: 'margin-top:1.5rem' }, _('Что реально запущено')),
				E('textarea', {
					id: 'yt-command',
					readonly: 'readonly',
					rows: 5,
					wrap: 'off',
					style: 'width:100%;font-family:monospace'
				}),

				E('h3', { style: 'margin-top:1.5rem' }, _('Последние события')),
				E('textarea', {
					id: 'yt-log',
					readonly: 'readonly',
					rows: 16,
					wrap: 'off',
					style: 'width:100%;font-family:monospace'
				})
			]);
		};

		poll.add(function() {
			return fs.exec_direct('/usr/libexec/ytunblock/status-json.sh').then(function(raw) {
				var data = {};
				try { data = JSON.parse((raw || '').trim()); } catch (e) {}

				var st = document.getElementById('yt-status');
				if (st)
					st.replaceChildren(data.status === 'running' ? badge('success', _('Работает')) : badge('', _('Остановлена')));

				var as = document.getElementById('yt-autostart');
				if (as)
					as.textContent = data.autostart === 'enabled' ? _('Включён') : _('Выключен');

				var ver = document.getElementById('yt-version');
				if (ver)
					ver.textContent = data.version || '—';

				var fw = document.getElementById('yt-firewall');
				if (fw) {
					var ok = data.nft_rule === 'ok' || data.nft_rule === 'legacy';
					fw.replaceChildren(ok ? badge('success', _('Готово')) : badge('important', _('Нужно обновить firewall')));
				}

				var toggle = document.getElementById('yt-start-stop');
				if (toggle) {
					var running = data.status === 'running';
					toggle.textContent = running ? _('Остановить') : _('Запустить');
					toggle.setAttribute('data-mode', running ? 'stop' : 'start');
					toggle.className = running ? 'btn cbi-button cbi-button-negative' : 'btn cbi-button cbi-button-positive';
				}

				var asb = document.getElementById('yt-autostart-btn');
				if (asb) {
					var enabled = data.autostart === 'enabled';
					asb.textContent = enabled ? _('Отключить автозапуск') : _('Включить автозапуск');
					asb.setAttribute('data-mode', enabled ? 'disable' : 'enable');
				}
			}).then(function() {
				return fs.exec_direct('/usr/bin/youtubeUnblock', ['--version']).then(function(res) {
					var ver = document.getElementById('yt-version');
					if (ver && (res || '').trim())
						ver.textContent = (res || '').trim();
				}).catch(function() {});
			}).then(function() {
				return fs.exec_direct('/sbin/logread', ['-e', 'ytunblock', '-l', '120']).catch(function() {
					return fs.exec_direct('/sbin/logread', ['-e', 'youtubeUnblock', '-l', '120']);
				}).then(function(res) {
					var log = document.getElementById('yt-log');
					if (log)
						log.value = (res || '').trim() || _('Пока пусто');
				});
			}).then(function() {
				return fs.exec_direct('/usr/libexec/ytunblock/build-command.sh', []).catch(function() { return ''; });
			}).then(function(res) {
				var cmd = document.getElementById('yt-command');
				if (cmd)
					cmd.value = (res || '').trim() || _('Команда пока недоступна');
			});
		}, 3);

		m.handleSave = null;
		m.handleSaveApply = null;
		m.handleReset = null;
		return m.render();
	}
});
