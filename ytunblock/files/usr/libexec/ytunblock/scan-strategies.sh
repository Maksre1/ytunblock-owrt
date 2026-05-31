#!/bin/sh
# ==============================================================================
#                 scan-strategies.sh - Auto Tuner for ytunblock
# ==============================================================================
# Автоматический сканер стратегий обхода DPI для ytunblock.
# Проверяет разные параметры фрагментации и фейк-пакетов без прерывания сети.
# ==============================================================================

TEST_HOST="youtube.com"
TEST_URL="https://www.youtube.com"
TIMEOUT=4
TEST_QUEUE=999
TEST_TABLE="ytunblock_probe"
LOG_FILE="/var/log/ytunblock-scan.log"

# Инициализация лог-файла
cat /dev/null > "$LOG_FILE"

log() {
    echo "[SCAN] $1" >> "$LOG_FILE"
    echo "$1"
}

cleanup() {
    # Полная зачистка временных правил nftables и процессов
    nft delete table inet "$TEST_TABLE" 2>/dev/null || true
    killall ytunblock_test 2>/dev/null || true
    pids=$(pgrep -f "queue-num=$TEST_QUEUE")
    [ -n "$pids" ] && kill -9 $pids 2>/dev/null || true
}

# Очистка при прерывании
trap "cleanup; /etc/init.d/ytunblock start >/dev/null 2>&1 || true" EXIT INT TERM

log "=== Запуск автоматического тестирования обхода DPI ==="
log "Тестируемый хост: $TEST_HOST"
log "----------------------------------------"

# Временно останавливаем основную службу для чистоты теста
log "Временно останавливаем основную службу ytunblock..."
/etc/init.d/ytunblock stop >/dev/null 2>&1 || true
nft delete chain inet fw4 ytunblock >/dev/null 2>&1 || true
sleep 1

# Проверка прямого соединения
log "Проверяем доступность хоста напрямую (без обхода)..."
http_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout $TIMEOUT "$TEST_URL" 2>/dev/null)
if [ "$http_code" = "200" ] || [ "$http_code" = "301" ] || [ "$http_code" = "302" ]; then
    log "✅ Доступ есть напрямую! HTTP код: $http_code. Обход блокировок не требуется."
    exit 0
fi
log "❌ Прямой доступ заблокирован (HTTP код: $http_code). Начинаем подбор стратегий..."

# Набор проверяемых стратегий:
# имя_стратегии | аргументы_демона | UCI_параметры
STRATEGIES="split_pos_1|--frag-sni-pos=1|frag=tcp:frag_sni_pos=1:fake_sni=0
split_pos_2|--frag-sni-pos=2|frag=tcp:frag_sni_pos=2:fake_sni=0
split_pos_3|--frag-sni-pos=3|frag=tcp:frag_sni_pos=3:fake_sni=0
split_pos_5|--frag-sni-pos=5|frag=tcp:frag_sni_pos=5:fake_sni=0
reverse_split|--frag-sni-pos=1 --frag-sni-reverse=1|frag=tcp:frag_sni_pos=1:frag_sni_reverse=1:fake_sni=0
fake_sni_pastseq|--fake-sni=1 --faking-strategy=pastseq|fake_sni=1:faking_strategy=pastseq
fake_sni_synfake|--synfake=1 --fake-sni=1|fake_sni=1:synfake=1
russia_balanced|--fake-sni=1 --faking-strategy=pastseq --frag-sni-pos=1 --frag-sni-reverse=1|fake_sni=1:faking_strategy=pastseq:frag=tcp:frag_sni_pos=1:frag_sni_reverse=1:frag_middle_sni=1"

best_name=""
best_uci=""

echo "$STRATEGIES" | while read -r line; do
    [ -z "$line" ] && continue
    
    strat_name=$(echo "$line" | cut -d'|' -f1)
    strat_args=$(echo "$line" | cut -d'|' -f2)
    strat_uci=$(echo "$line" | cut -d'|' -f3)

    log "Тестируем стратегию: $strat_name..."
    
    # 1. Запуск тестового демона на временном порту
    cp /usr/bin/youtubeUnblock /tmp/ytunblock_test 2>/dev/null || cp /usr/bin/ytunblock /tmp/ytunblock_test
    /tmp/ytunblock_test --queue-num=$TEST_QUEUE --packet-mark=65536 --tls=enabled $strat_args --quic-drop >/dev/null 2>&1 &
    sleep 1.5

    # 2. Добавление временных nftables правил
    nft add table inet "$TEST_TABLE" 2>/dev/null
    nft add chain inet "$TEST_TABLE" output { type filter hook output priority 0 \; } 2>/dev/null
    nft add rule inet "$TEST_TABLE" output tcp dport 443 tls sni "$TEST_HOST" counter queue num $TEST_QUEUE bypass 2>/dev/null
    nft add rule inet "$TEST_TABLE" output tcp dport 443 tls sni "www.$TEST_HOST" counter queue num $TEST_QUEUE bypass 2>/dev/null

    # 3. Запрос
    http_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout $TIMEOUT "$TEST_URL" 2>/dev/null)
    
    if [ "$http_code" = "200" ] || [ "$http_code" = "301" ] || [ "$http_code" = "302" ]; then
        log "  -> 🎉 РАБОТАЕТ! HTTP Код: $http_code"
        # Записываем победителя в файл, так как подоболочка while не сохраняет внешние переменные
        echo "$strat_name|$strat_uci" > /tmp/ytunblock_winner
        cleanup
        break
    else
        log "  -> ❌ Не сработало (HTTP Код: $http_code)"
    fi
    
    cleanup
    sleep 1
done

rm -f /tmp/ytunblock_test

if [ -f /tmp/ytunblock_winner ]; then
    best_name=$(cut -d'|' -f1 /tmp/ytunblock_winner)
    best_uci=$(cut -d'|' -f2 /tmp/ytunblock_winner)
    rm -f /tmp/ytunblock_winner
fi

if [ -n "$best_name" ]; then
    log "----------------------------------------"
    log "Победитель: $best_name"
    log "Применяем параметры в UCI..."
    
    # Сброс настроек перед сохранением
    /usr/share/ytunblock/defaults.sh --force >/dev/null 2>&1 || true
    
    # Записываем параметры победителя в UCI
    # Формат uci: option=value
    OLD_IFS=$IFS
    IFS=":"
    for param in $best_uci; do
        opt_name=$(echo "$param" | cut -d'=' -f1)
        opt_val=$(echo "$param" | cut -d'=' -f2)
        if [ -n "$opt_name" ] && [ -n "$opt_val" ]; then
            uci set ytunblock.@section[0]."$opt_name"="$opt_val"
        fi
    done
    IFS=$OLD_IFS
    
    # Переименуем блок правил для наглядности
    uci set ytunblock.@section[0].name="Автоподбор: $best_name"
    
    uci commit ytunblock
    log "Конфигурация сохранена. Перезапуск службы ytunblock..."
    /etc/init.d/ytunblock restart
    log "✅ Служба успешно перезапущена с рабочей стратегией!"
else
    log "----------------------------------------"
    log "❌ ВНИМАНИЕ: Ни одна из стратегий не сработала."
    log "Возможно, ваш провайдер полностью блокирует трафик к YouTube."
fi
