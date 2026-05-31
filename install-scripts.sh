#!/bin/sh
# ==============================================================================
#           install-scripts.sh - One-line installer for ytunblock-owrt
# ==============================================================================
# Скачивает все скрипты, конфиги и LuCI веб-интерфейс из репозитория и
# настраивает их на вашем роутере OpenWrt.
# ==============================================================================

REPO="https://raw.githubusercontent.com/Maksre1/ytunblock-owrt/main"

log() {
    echo -e "\033[1;34m[YTunblock Installer]\033[0m $1"
}

warn() {
    echo -e "\033[1;33m[YTunblock Installer] ВНИМАНИЕ: $1\033[0m"
}

success() {
    echo -e "\033[1;32m[YTunblock Installer] УСПЕХ: $1\033[0m"
}

# Проверка на root
if [ "$(id -u)" -ne 0 ]; then
    warn "Этот скрипт должен быть запущен от имени root."
    exit 1
fi

# Проверка зависимостей загрузки
DOWNLOADER=""
if which wget >/dev/null 2>&1; then
    DOWNLOADER="wget -q -O"
elif which curl >/dev/null 2>&1; then
    DOWNLOADER="curl -s -f -o"
else
    warn "Утилиты wget или curl не найдены в системе. Установите одну из них перед запуском."
    exit 1
fi

# 1. Остановка конфликтующих служб
log "Остановка старых служб и очистка..."
/etc/init.d/youtubeUnblock stop 2>/dev/null || true
/etc/init.d/youtubeUnblock disable 2>/dev/null || true
killall youtubeUnblock 2>/dev/null || true
killall chameleon-daemon 2>/dev/null || true
[ -f /usr/share/nftables.d/ruleset-post/537-youtubeUnblock.nft ] && mv /usr/share/nftables.d/ruleset-post/537-youtubeUnblock.nft /usr/share/nftables.d/ruleset-post/537-youtubeUnblock.nft.bak || true

# 2. Создание директорий
log "Создание директорий на роутере..."
mkdir -p /etc/config /etc/init.d /etc/uci-defaults \
         /usr/share/nftables.d/ruleset-post \
         /usr/share/ytunblock/presets \
         /usr/libexec/ytunblock \
         /usr/share/luci/menu.d \
         /usr/share/rpcd/acl.d \
         /www/luci-static/resources/view/ytunblock

# 3. Функция загрузки
download_file() {
    local rel_path="$1"
    local dest_path="$2"
    local mode="$3"
    
    log "Скачивание: $rel_path -> $dest_path"
    if ! $DOWNLOADER "$dest_path" "$REPO/$rel_path"; then
        warn "Не удалось скачать файл: $rel_path"
        exit 1
    fi
    chmod "$mode" "$dest_path"
}

# 4. Скачивание файлов
download_file "ytunblock/files/etc/config/ytunblock" "/etc/config/ytunblock" "0644"
download_file "ytunblock/files/etc/config/ytunblock" "/usr/share/ytunblock/default.config" "0644"
download_file "ytunblock/files/etc/init.d/ytunblock" "/etc/init.d/ytunblock" "0755"
download_file "ytunblock/files/etc/uci-defaults/99-ytunblock" "/etc/uci-defaults/99-ytunblock" "0755"
download_file "ytunblock/files/nftables.d/537-ytunblock.nft" "/usr/share/nftables.d/ruleset-post/537-ytunblock.nft" "0644"

download_file "ytunblock/files/usr/share/ytunblock/defaults.sh" "/usr/share/ytunblock/defaults.sh" "0755"
download_file "ytunblock/files/usr/share/ytunblock/presets/default.sh" "/usr/share/ytunblock/presets/default.sh" "0755"
download_file "ytunblock/files/usr/share/ytunblock/presets/lite.sh" "/usr/share/ytunblock/presets/lite.sh" "0755"
download_file "ytunblock/files/usr/share/ytunblock/presets/russia_aggressive.sh" "/usr/share/ytunblock/presets/russia_aggressive.sh" "0755"
download_file "ytunblock/files/usr/share/ytunblock/presets/russia_balanced.sh" "/usr/share/ytunblock/presets/russia_balanced.sh" "0755"
download_file "ytunblock/files/usr/share/ytunblock/presets/russia_balanced_discord.sh" "/usr/share/ytunblock/presets/russia_balanced_discord.sh" "0755"

download_file "ytunblock/files/usr/libexec/ytunblock/status-json.sh" "/usr/libexec/ytunblock/status-json.sh" "0755"
download_file "ytunblock/files/usr/libexec/ytunblock/scan-strategies.sh" "/usr/libexec/ytunblock/scan-strategies.sh" "0755"
download_file "ytunblock/files/usr/libexec/ytunblock/apply-preset.sh" "/usr/libexec/ytunblock/apply-preset.sh" "0755"
download_file "ytunblock/files/usr/libexec/ytunblock/ensure-config.sh" "/usr/libexec/ytunblock/ensure-config.sh" "0755"
download_file "ytunblock/files/usr/libexec/ytunblock/build-command.sh" "/usr/libexec/ytunblock/build-command.sh" "0755"

download_file "luci-app-ytunblock/root/usr/share/luci/menu.d/luci-app-ytunblock.json" "/usr/share/luci/menu.d/luci-app-ytunblock.json" "0644"
download_file "luci-app-ytunblock/root/usr/share/rpcd/acl.d/luci-app-ytunblock.json" "/usr/share/rpcd/acl.d/luci-app-ytunblock.json" "0644"
download_file "luci-app-ytunblock/htdocs/luci-static/resources/view/ytunblock/diagnostics.js" "/www/luci-static/resources/view/ytunblock/diagnostics.js" "0644"
download_file "luci-app-ytunblock/htdocs/luci-static/resources/view/ytunblock/dashboard.js" "/www/luci-static/resources/view/ytunblock/dashboard.js" "0644"
download_file "luci-app-ytunblock/htdocs/luci-static/resources/view/ytunblock/settings.js" "/www/luci-static/resources/view/ytunblock/settings.js" "0644"

# 5. Симлинк
log "Настройка символических ссылок..."
ln -sf /usr/bin/youtubeUnblock /usr/bin/ytunblock

# 6. Применение конфигурации
log "Инициализация UCI конфигурации через uci-defaults..."
/etc/uci-defaults/99-ytunblock

log "Сброс кэша веб-интерфейса..."
rm -rf /tmp/luci-indexcache* /tmp/luci-modulecache*

log "Перезапуск веб-серверов и системных служб..."
/etc/init.d/rpcd restart
/etc/init.d/uhttpd restart
/etc/init.d/firewall reload

log "Активация службы ytunblock..."
/etc/init.d/ytunblock enable
/etc/init.d/ytunblock start

success "Скрипты ytunblock-owrt успешно установлены и запущены!"
log "Откройте страницу Службы -> YT Unblock в LuCI веб-интерфейсе роутера."
