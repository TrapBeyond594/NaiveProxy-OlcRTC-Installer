#!/bin/bash
# NaiveProxy + OlcRTC Manager
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/scripts/utils.sh"
source "$SCRIPT_DIR/scripts/manager.sh"
source "$SCRIPT_DIR/scripts/update.sh"

check_root

main_menu() {
    while true; do
        clear
        echo -e "${GREEN}===============================================${NC}"
        echo -e "${YELLOW}   NaiveProxy + OlcRTC Manager v2.0${NC}"
        echo -e "${GREEN}===============================================${NC}"
        echo "1) 📦 Установка и Обновление"
        echo "2) 🛡️ NaiveProxy (Пользователи и Ссылки)"
        echo "3) 🚀 OlcRTC (Room ID и Ссылки)"
        echo "4) ⚙️ Оптимизация Системы"
        echo "5) 🛠️ Управление Сервисами (Start/Stop)"
        echo "6) 📧 Настроить Email (SMTP)"
        echo "7) 📝 Просмотр Логов"
        echo "8) 🗑️ Удалить всё (Uninstall)"
        echo "0) 🚪 Выход"
        echo -e "${GREEN}===============================================${NC}"
        read -p "Выберите опцию: " choice

        case $choice in
            1) install_update_menu ;;
            2) naive_manager_menu ;;
            3) olcrtc_manager_menu ;;
            4) optimize_system ; read -p "Нажмите Enter..." ;;
            5) service_management ;;
            6) configure_smtp ;;
            7) view_logs ;;
            8) "$SCRIPT_DIR/scripts/uninstall.sh" ;;
            0) exit 0 ;;
            *) log_error "Неверный выбор" ; sleep 1 ;;
        esac
    done
}

install_update_menu() {
    clear
    echo "--- Установка и Обновление ---"
    echo "1) Полная установка (с нуля)"
    echo "2) Проверить обновления репозитория"
    echo "3) Обновить репозиторий"
    echo "4) Обновить систему (apt/dnf/pacman)"
    echo "5) Настроить авто-проверку обновлений (cron)"
    echo "0) Назад"
    read -p "Выберите: " o
    case $o in
        1) "$SCRIPT_DIR/scripts/install.sh" ;;
        2) check_repo_updates ; read -p "Нажмите Enter..." ;;
        3) update_repo ; read -p "Нажмите Enter..." ;;
        4) update_system ; read -p "Нажмите Enter..." ;;
        5) setup_cron_updates ; read -p "Нажмите Enter..." ;;
    esac
}

naive_manager_menu() {
    while true; do
        clear
        echo "--- Менеджер NaiveProxy ---"
        echo "1) Добавить пользователя"
        echo "2) Список пользователей и ссылок"
        echo "3) Удалить пользователя"
        echo "4) Настроить Домен/Email (Первичная настройка)"
        echo "0) Назад"
        read -p "Выберите: " o
        case $o in
            1)
                read -p "Имя пользователя: " u
                read -p "Пароль (пусто для авто): " p
                [ -z "$p" ] && p=$(openssl rand -base64 12)
                read -p "Заметка (для кого): " n
                add_link "naive" "$u" "$p" "$n"
                rebuild_caddyfile
                log_info "Пользователь добавлен." ; sleep 1
                ;;
            2)
                list_links "naive"
                read -p "Хотите отправить ссылку на почту? (y/n): " em
                if [[ $em == "y" ]]; then
                    read -p "Введите ID пользователя: " sid
                    read -p "Email получателя: " temail
                    local link_data=$(jq -r ".[] | select(.service == \"naive\" and .id == \"$sid\")" "$DB_FILE")
                    local d=$(get_config "domain")
                    local pr=$(get_config "port")
                    local pass=$(echo "$link_data" | jq -r '.password')
                    local body="Ваша ссылка NaiveProxy:\nnaive+https://$sid:$pass@$d:$pr"
                    send_link_email "$temail" "NaiveProxy Config" "$body"
                fi
                read -p "Нажмите Enter..."
                ;;
            3)
                read -p "ID пользователя для удаления: " sid
                delete_link "naive" "$sid"
                rebuild_caddyfile
                log_info "Удалено." ; sleep 1
                ;;
            4) configure_naive_basic ;;
            0) break ;;
        esac
    done
}

configure_naive_basic() {
    read -p "Введите домен: " domain
    read -p "Введите Email для SSL: " email
    read -p "Введите порт (443): " port
    port=${port:-443}

    save_config "$domain" "$email" "$port"

    # Create initial link if none
    if [ $(jq 'length' "$DB_FILE") -eq 0 ]; then
         u=$(openssl rand -hex 4)
         p=$(openssl rand -base64 12)
         add_link "naive" "$u" "$p" "Admin"
    fi
    rebuild_caddyfile
    open_port "$port"
}

configure_smtp() {
    clear
    echo "--- Настройка Email (SMTP) ---"
    read -p "SMTP Хост (например, smtp.gmail.com): " host
    read -p "SMTP Порт (например, 587): " port
    read -p "Ваш Email (отправитель): " user
    read -p "Пароль (или App Password): " pass
    read -p "Использовать TLS? (y/n): " tls

    local auth="on"
    local starttls="on"
    [[ $tls != "y" ]] && starttls="off"

    cat > ~/.msmtprc << EOF
defaults
auth           $auth
tls            on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
logfile        ~/.msmtp.log

account        default
host           $host
port           $port
from           $user
user           $user
password       $pass
tls_starttls   $starttls
EOF
    chmod 600 ~/.msmtprc
    log_info "Настройки SMTP сохранены."
    read -p "Нажмите Enter..."
}

olcrtc_manager_menu() {
    while true; do
        clear
        echo "--- Менеджер OlcRTC ---"
        echo "1) Сгенерировать новый Room ID / Ключ"
        echo "2) Просмотр сохраненных ссылок"
        echo "3) Удалить запись"
        echo "4) Настроить сервис (Systemd)"
        echo "0) Назад"
        read -p "Выберите: " o
        case $o in
            1)
                room_id=$(olcrtc -mode gen -carrier wbstream -dns 1.1.1.1:53 -amount 1 -data /opt/olcrtc/data)
                key=$(openssl rand -hex 32)
                read -p "Заметка (для кого): " n
                add_link "olcrtc" "$room_id" "$key" "$n"
                log_info "Сгенерировано: RoomID: $room_id, Key: $key"
                read -p "Нажмите Enter..."
                ;;
            2)
                list_links "olcrtc"
                read -p "Хотите отправить на почту? (y/n): " em
                if [[ $em == "y" ]]; then
                    read -p "Введите Room ID: " sid
                    read -p "Email получателя: " temail
                    local link_data=$(jq -r ".[] | select(.service == \"olcrtc\" and .id == \"$sid\")" /etc/naive-olcrtc/links.json)
                    local pass=$(echo "$link_data" | jq -r '.password')
                    local body="Данные OlcRTC:\nRoom ID: $sid\nKey: $pass"
                    send_link_email "$temail" "OlcRTC Config" "$body"
                fi
                read -p "Нажмите Enter..."
                ;;
            3)
                read -p "Room ID для удаления: " sid
                delete_link "olcrtc" "$sid"
                log_info "Удалено." ; sleep 1
                ;;
            4) configure_olcrtc_basic ;;
            0) break ;;
        esac
    done
}

configure_olcrtc_basic() {
    read -p "Room ID: " rid
    read -p "Client ID (default): " cid
    cid=${cid:-default}
    read -p "Key: " key

    cp "$SCRIPT_DIR/services/olcrtc.service" /etc/systemd/system/
    sed -i "s/ROOM_ID/$rid/g; s/CLIENT_ID/$cid/g; s/KEY/$key/g" /etc/systemd/system/olcrtc.service
    mkdir -p /opt/olcrtc/data
    systemctl daemon-reload
    log_info "OlcRTC сервис обновлен."
}

service_management() {
    clear
    echo "--- Управление сервисами ---"
    echo "1) NaiveProxy: Start | 2) Stop | 3) Restart | 4) Status"
    echo "5) OlcRTC: Start     | 6) Stop | 7) Restart | 8) Status"
    echo "0) Назад"
    read -p "Выберите: " schoice
    case $schoice in
        1) systemctl start caddy ;;
        2) systemctl stop caddy ;;
        3) systemctl restart caddy ;;
        4) systemctl status caddy ;;
        5) systemctl start olcrtc ;;
        6) systemctl stop olcrtc ;;
        7) systemctl restart olcrtc ;;
        8) systemctl status olcrtc ;;
    esac
    read -p "Нажмите Enter..."
}

view_logs() {
    clear
    echo "--- Просмотр логов ---"
    echo "1) NaiveProxy (Caddy)"
    echo "2) OlcRTC"
    read -p "Выберите: " lchoice
    case $lchoice in
        1) journalctl -u caddy -n 50 --no-pager ;;
        2) journalctl -u olcrtc -n 50 --no-pager ;;
    esac
    read -p "Нажмите Enter..."
}

main_menu
