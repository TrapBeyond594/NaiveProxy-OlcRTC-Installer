#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

check_root

log_warn "ВНИМАНИЕ: Это полностью удалит NaiveProxy и OlcRTC!"
read -p "Вы уверены? (y/n): " confirm
if [[ $confirm != "y" ]]; then exit 0; fi

log_info "Остановка сервисов..."
systemctl stop naiveproxy caddy olcrtc 2>/dev/null
systemctl disable naiveproxy caddy olcrtc 2>/dev/null

log_info "Удаление системных юнитов..."
rm -f /etc/systemd/system/naiveproxy.service
rm -f /etc/systemd/system/olcrtc.service
systemctl daemon-reload

log_info "Удаление бинарных файлов..."
rm -f /usr/local/bin/caddy
rm -f /usr/local/bin/olcrtc
rm -f /usr/local/bin/mage

log_info "Удаление конфигураций и данных..."
rm -rf /etc/caddy
rm -rf /opt/olcrtc
rm -rf /var/www/html
rm -rf /etc/naive-olcrtc

log_info "Удаление сетевых оптимизаций..."
rm -f /etc/sysctl.d/99-naive-optimizations.conf
rm -f /etc/security/limits.d/99-naive-limits.conf
sysctl --system >/dev/null 2>&1

log_info "Удаление завершено."
