#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

check_root

remove_naive() {
    log_info "Удаление NaiveProxy..."
    systemctl stop caddy 2>/dev/null
    systemctl disable caddy 2>/dev/null
    rm -f /etc/systemd/system/naiveproxy.service /etc/systemd/system/caddy.service
    rm -f /usr/local/bin/caddy
    rm -rf /etc/caddy
    rm -rf /var/www/html
    # Remove from DB if exists
    jq 'del(.[] | select(.service == "naive"))' /etc/naive-olcrtc/links.json > /etc/naive-olcrtc/links.json.tmp && mv /etc/naive-olcrtc/links.json.tmp /etc/naive-olcrtc/links.json
    log_info "NaiveProxy удален."
}

remove_olcrtc() {
    log_info "Удаление OlcRTC..."
    systemctl stop olcrtc 2>/dev/null
    systemctl disable olcrtc 2>/dev/null
    rm -f /etc/systemd/system/olcrtc.service
    rm -f /usr/local/bin/olcrtc
    rm -rf /opt/olcrtc
    jq 'del(.[] | select(.service == "olcrtc"))' /etc/naive-olcrtc/links.json > /etc/naive-olcrtc/links.json.tmp && mv /etc/naive-olcrtc/links.json.tmp /etc/naive-olcrtc/links.json
    log_info "OlcRTC удален."
}

remove_all() {
    remove_naive
    remove_olcrtc
    log_info "Удаление общих файлов и настроек..."
    rm -rf /etc/naive-olcrtc
    rm -f /etc/sysctl.d/99-naive-optimizations.conf
    rm -f /etc/security/limits.d/99-naive-limits.conf
    sysctl --system >/dev/null 2>&1
    log_info "Все компоненты удалены."
}

case "$1" in
    --naive) remove_naive ;;
    --olcrtc) remove_olcrtc ;;
    --all) remove_all ;;
    *)
        log_warn "Использование: $0 [--naive | --olcrtc | --all]"
        exit 1
        ;;
esac

systemctl daemon-reload
