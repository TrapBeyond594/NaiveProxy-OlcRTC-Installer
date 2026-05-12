#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

check_repo_updates() {
    log_info "Проверка обновлений репозитория..."
    git fetch
    local local_hash=$(git rev-parse HEAD)
    local remote_hash=$(git rev-parse @{u})

    if [ "$local_hash" != "$remote_hash" ]; then
        log_warn "Доступно обновление репозитория!"
        return 0
    else
        log_info "Репозиторий актуален."
        return 1
    fi
}

update_repo() {
    log_info "Обновление репозитория..."
    git pull
    log_info "Обновлено до $(git rev-parse --short HEAD)"
}

update_system() {
    log_info "Обновление системы..."
    local os=$(get_os)
    case "$os" in
        debian|ubuntu|dietpi)
            apt-get update && apt-get upgrade -y
            ;;
        fedora|centos)
            dnf update -y
            ;;
        arch)
            pacman -Syu --noconfirm
            ;;
    esac
}

update_naive() {
    log_info "Обновление NaiveProxy (Пересборка)..."
    # Call install script parts or duplicate logic if modularized
    # For now, we reuse install_caddy_naive logic
    source "$SCRIPT_DIR/install.sh"
    install_go
    install_caddy_naive
    systemctl restart caddy || systemctl restart naiveproxy
    log_info "NaiveProxy обновлен."
}

update_olcrtc() {
    log_info "Обновление OlcRTC (Пересборка)..."
    source "$SCRIPT_DIR/install.sh"
    install_go
    install_mage
    install_olcrtc
    systemctl restart olcrtc
    log_info "OlcRTC обновлен."
}

setup_cron_updates() {
    log_info "Настройка автоматической проверки обновлений (ежедневно)..."
    # Check if already in crontab
    crontab -l 2>/dev/null | grep -v "$SCRIPT_DIR/update.sh --auto-check" | crontab -
    (crontab -l 2>/dev/null; echo "0 0 * * * $SCRIPT_DIR/update.sh --auto-check") | crontab -
    log_info "Cron задача добавлена/обновлена."
}

if [[ "$1" == "--auto-check" ]]; then
    if check_repo_updates; then
        log_warn "Обнаружено обновление в автоматическом режиме."
        # Auto-update if desired or just log
        update_repo
    fi
    exit 0
fi
