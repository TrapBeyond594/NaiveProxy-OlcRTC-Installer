#!/bin/bash
# Check if running from correct directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/scripts/utils.sh"

check_root

main_menu() {
    while true; do
        clear
        echo "==============================================="
        echo "   NaiveProxy + OlcRTC Installer & Manager"
        echo "==============================================="
        echo "1) Установить всё (Dependencies, Caddy, OlcRTC)"
        echo "2) Настроить NaiveProxy (Caddy)"
        echo "3) Настроить OlcRTC"
        echo "4) Управление сервисами (Start/Stop/Status)"
        echo "5) Просмотр логов"
        echo "6) Включить BBR"
        echo "7) Полезные команды и инфо"
        echo "0) Выход"
        echo "==============================================="
        read -p "Выберите опцию: " choice

        case $choice in
            1) "$SCRIPT_DIR/scripts/install.sh" ;;
            2) configure_naive ;;
            3) configure_olcrtc ;;
            4) service_management ;;
            5) view_logs ;;
            6) enable_bbr ; read -p "Нажмите Enter для продолжения..." ;;
            7) show_info ;;
            0) exit 0 ;;
            *) log_error "Неверный выбор" ; sleep 1 ;;
        esac
    done
}

configure_naive() {
    clear
    echo "--- Настройка NaiveProxy ---"
    read -p "Введите домен (например, example.com): " domain
    read -p "Введите Email для SSL (Let's Encrypt): " email
    read -p "Введите порт (по умолчанию 443): " port
    port=${port:-443}

    if check_port "$port"; then
        log_warn "Порт $port уже используется другим процессом!"
        read -p "Продолжить всё равно? (y/n): " confirm
        if [[ $confirm != "y" ]]; then return; fi
    fi

    read -p "Введите имя пользователя (оставьте пустым для автогенерации): " user
    if [ -z "$user" ]; then
        user=$(openssl rand -base64 12 | tr -dc 'A-Za-z0-9' | head -c 12)
        log_info "Сгенерирован логин: $user"
    fi
    read -p "Введите пароль (оставьте пустым для автогенерации): " pass
    if [ -z "$pass" ]; then
        pass=$(openssl rand -base64 18 | tr -dc 'A-Za-z0-9' | head -c 18)
        log_info "Сгенерирован пароль: $pass"
    fi

    cat > /etc/caddy/Caddyfile << EOF
{
    order forward_proxy before file_server
}
$domain:$port {
    tls $email
    forward_proxy {
        basic_auth $user $pass
        hide_ip
        hide_via
        probe_resistance
    }
    file_server {
        root /var/www/html
    }
}
EOF

    cp "$SCRIPT_DIR/services/naiveproxy.service" /etc/systemd/system/
    systemctl daemon-reload
    open_port "$port"
    log_info "Конфигурация NaiveProxy сохранена в /etc/caddy/Caddyfile"
    read -p "Нажмите Enter для продолжения..."
}

configure_olcrtc() {
    clear
    echo "--- Настройка OlcRTC ---"
    read -p "Введите Room ID (оставьте пустым для генерации): " room_id
    if [ -z "$room_id" ]; then
        if ! command -v olcrtc >/dev/null 2>&1; then
            log_error "Бинарный файл olcrtc не найден. Сначала выполните установку (пункт 1)."
            read -p "Нажмите Enter для возврата..."
            return
        fi
        room_id=$(olcrtc -mode gen -carrier wbstream -dns 1.1.1.1:53 -amount 1 -data /opt/olcrtc/data)
        log_info "Сгенерирован Room ID: $room_id"
    fi
    read -p "Введите Client ID (по умолчанию default): " client_id
    client_id=${client_id:-default}
    read -p "Введите Key (32 hex символа, оставьте пустым для генерации): " key
    if [ -z "$key" ]; then
        key=$(openssl rand -hex 32)
        log_info "Сгенерирован Key: $key"
    fi

    cp "$SCRIPT_DIR/services/olcrtc.service" /etc/systemd/system/
    sed -i "s/ROOM_ID/$room_id/g; s/CLIENT_ID/$client_id/g; s/KEY/$key/g" /etc/systemd/system/olcrtc.service

    mkdir -p /opt/olcrtc/data
    systemctl daemon-reload
    log_info "Конфигурация OlcRTC сохранена в системный сервис."
    read -p "Нажмите Enter для продолжения..."
}

service_management() {
    clear
    echo "--- Управление сервисами ---"
    echo "1) NaiveProxy: Start"
    echo "2) NaiveProxy: Stop"
    echo "3) NaiveProxy: Restart"
    echo "4) NaiveProxy: Status"
    echo "----------------------------"
    echo "5) OlcRTC: Start"
    echo "6) OlcRTC: Stop"
    echo "7) OlcRTC: Restart"
    echo "8) OlcRTC: Status"
    echo "0) Назад"
    read -p "Выберите опцию: " schoice

    case $schoice in
        1) systemctl start naiveproxy ;;
        2) systemctl stop naiveproxy ;;
        3) systemctl restart naiveproxy ;;
        4) systemctl status naiveproxy ;;
        5) systemctl start olcrtc ;;
        6) systemctl stop olcrtc ;;
        7) systemctl restart olcrtc ;;
        8) systemctl status olcrtc ;;
        *) return ;;
    esac
    read -p "Нажмите Enter для продолжения..."
}

view_logs() {
    clear
    echo "--- Просмотр логов ---"
    echo "1) NaiveProxy"
    echo "2) OlcRTC"
    echo "0) Назад"
    read -p "Выберите опцию: " lchoice

    case $lchoice in
        1) journalctl -u naiveproxy -n 50 --no-pager ;;
        2) journalctl -u olcrtc -n 50 --no-pager ;;
        *) return ;;
    esac
    read -p "Нажмите Enter для продолжения..."
}

show_info() {
    clear
    echo "--- Полезная информация ---"
    echo "NaiveProxy URL для клиента:"
    if [ -f /etc/caddy/Caddyfile ]; then
        # Try to extract values
        local domain=$(grep -v "{" /etc/caddy/Caddyfile | grep ":" | head -n1 | cut -d":" -f1 | xargs)
        local port=$(grep -v "{" /etc/caddy/Caddyfile | grep ":" | head -n1 | cut -d":" -f2 | cut -d" " -f1 | xargs)
        local user=$(grep "basic_auth" /etc/caddy/Caddyfile | head -n1 | awk '{print $2}')
        local pass=$(grep "basic_auth" /etc/caddy/Caddyfile | head -n1 | awk '{print $3}')
        echo "naive+https://$user:$pass@$domain:$port"
    else
        echo "Caddyfile не найден. Сначала настройте NaiveProxy."
    fi
    echo ""
    echo "Команды:"
    echo "  systemctl status caddy      - статус NaiveProxy"
    echo "  systemctl status olcrtc     - статус OlcRTC"
    echo "  journalctl -u caddy -f      - логи Caddy в реальном времени"
    echo ""
    read -p "Нажмите Enter для продолжения..."
}

main_menu
