# ytunblock-owrt

Форк [Waujito/youtubeUnblock](https://github.com/Waujito/youtubeUnblock) для **OpenWrt 23.x–25.x** с улучшенным веб-интерфейсом LuCI.

## Возможности

- Сборка демона `youtubeUnblock` из upstream (v1.3.0+)
- Пакет `ytunblock` с procd, автоперезапуском и UCI `/etc/config/ytunblock`
- Правила **nftables** для firewall4
- **LuCI**: обзор, настройки, диагностика, быстрые профили
- Профили: по умолчанию, лёгкий, РФ сбалансированный, РФ агрессивный
- Миграция конфига с `youtubeUnblock` → `ytunblock`
- Поддержка **apk** (OpenWrt 25) и **opkg**

## Установка на роутер

### Из feed (рекомендуется)

```sh
# В каталоге OpenWrt SDK / buildroot:
echo 'src-git ytunblock https://github.com/Maksre1/ytunblock-owrt.git;main' >> feeds.conf
./scripts/feeds update ytunblock
./scripts/feeds install ytunblock luci-app-ytunblock
make package/ytunblock/compile package/luci-app-ytunblock/compile V=s
```

Скопируйте `.ipk` / `.apk` из `bin/packages/...` на роутер и установите:

```sh
# OpenWrt 25 (apk)
apk add ./ytunblock_*.apk ./luci-app-ytunblock_*.apk

# OpenWrt 23–24 (opkg)
opkg install ./ytunblock_*.ipk ./luci-app-ytunblock_*.ipk
```

### Зависимости

```sh
apk add kmod-nft-queue kmod-nf-conntrack firewall4
# или
opkg install kmod-nft-queue kmod-nf-conntrack
```

После установки: **Службы → YT Unblock** в LuCI, либо:

```sh
/etc/init.d/ytunblock enable
/etc/init.d/ytunblock start
/etc/init.d/firewall reload
```

## LuCI

| Раздел | Описание |
|--------|----------|
| **Обзор** | Статус, зависимости, профили, журнал |
| **Настройки** | Полная конфигурация (TLS, UDP, домены) |
| **Диагностика** | Модули ядра, nftables |

## Профили (CLI)

```sh
/usr/libexec/ytunblock/apply-preset.sh russia_balanced
/usr/libexec/ytunblock/apply-preset.sh lite
/usr/libexec/ytunblock/apply-preset.sh default
```

## UCI

```sh
uci set ytunblock.ytunblock.enabled=1
uci commit ytunblock
/etc/init.d/ytunblock restart
```

## Отличия от upstream

| | youtubeUnblock | ytunblock-owrt |
|---|----------------|----------------|
| Конфиг UCI | `youtubeUnblock` | `ytunblock` (+ миграция) |
| Init | `youtubeUnblock` | `ytunblock` + respawn |
| LuCI | базовый | профили, диагностика, RU |
| OpenWrt 25 | частично | apk, явные DEPENDS |

## Лицензия

Демон — **GPL-3.0** (как upstream). Пакеты и LuCI — GPL-3.0.

Используйте **только для YouTube** в соответствии с законодательством вашей страны.
