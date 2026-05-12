#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

check_root

remove_naive() {
    log_info "Удаление NaiveProxy..."

    # Stop and disable services
    systemctl stop caddy 2>/dev/null
    systemctl disable caddy 2>/dev/null
    systemctl stop naiveproxy 2>/dev/null
    systemctl disable naiveproxy 2>/dev/null

    # Remove systemd units
    rm -f /etc/systemd/system/naiveproxy.service /etc/systemd/system/caddy.service

    # Remove binary
    [ -f /usr/local/bin/caddy ] && rm -f /usr/local/bin/caddy

    # Remove configs
    [ -d /etc/caddy ] && rm -rf /etc/caddy

    # Remove web data
    [ -d /var/www/html ] && rm -rf /var/www/html

    # Remove from DB if exists
    if [ -f /etc/naive-olcrtc/links.json ] && command -v jq >/dev/null 2>&1; then
        jq 'del(.[] | select(.service == "naive"))' /etc/naive-olcrtc/links.json > /etc/naive-olcrtc/links.json.tmp && mv /etc/naive-olcrtc/links.json.tmp /etc/naive-olcrtc/links.json
    fi

    log_info "NaiveProxy полностью удален."
}

remove_olcrtc() {
    log_info "Удаление OlcRTC..."

    # Stop and disable services
    systemctl stop olcrtc 2>/dev/null
    systemctl disable olcrtc 2>/dev/null

    # Remove systemd units
    rm -f /etc/systemd/system/olcrtc.service

    # Remove binary
    [ -f /usr/local/bin/olcrtc ] && rm -f /usr/local/bin/olcrtc

    # Remove data and configs
    [ -d /opt/olcrtc ] && rm -rf /opt/olcrtc

    # Remove from DB if exists
    if [ -f /etc/naive-olcrtc/links.json ] && command -v jq >/dev/null 2>&1; then
        jq 'del(.[] | select(.service == "olcrtc"))' /etc/naive-olcrtc/links.json > /etc/naive-olcrtc/links.json.tmp && mv /etc/naive-olcrtc/links.json.tmp /etc/naive-olcrtc/links.json
    fi

    log_info "OlcRTC полностью удален."
}

cleanup_common() {
    log_info "Удаление общих файлов и настроек..."

    # Remove DB and internal configs
    [ -d /etc/naive-olcrtc ] && rm -rf /etc/naive-olcrtc

    # Remove optimizations
    rm -f /etc/sysctl.d/99-naive-bbr.conf
    rm -f /etc/sysctl.d/99-naive-advanced.conf
    rm -f /etc/sysctl.d/99-naive-optimizations.conf
    rm -f /etc/security/limits.d/99-naive-limits.conf

    # Apply sysctl changes
    sysctl --system >/dev/null 2>&1

    # Remove Cron tasks
    if crontab -l 2>/dev/null | grep -q "update.sh --auto-check"; then
        crontab -l | grep -v "update.sh --auto-check" | crontab -
        log_info "Авто-обновления (Cron) удалены."
    fi

    # Remove SMTP configs
    [ -f "$HOME/.msmtprc" ] && rm -f "$HOME/.msmtprc"
    [ -f "$HOME/.msmtp.log" ] && rm -f "$HOME/.msmtp.log"

    log_info "Общие настройки очищены."
}

remove_all() {
    remove_naive
    remove_olcrtc
    cleanup_common
    log_info "Все компоненты удалены с корнями."
}

case "$1" in
    --naive)
        remove_naive
        systemctl daemon-reload
        ;;
    --olcrtc)
        remove_olcrtc
        systemctl daemon-reload
        ;;
    --all)
        remove_all
        systemctl daemon-reload
        ;;
    *)
        log_warn "Использование: $0 [--naive | --olcrtc | --all]"
        exit 1
        ;;
esac
