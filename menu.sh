#!/bin/bash
# NaiveProxy + OlcRTC Manager
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$BASE_DIR/scripts/utils.sh"
source "$BASE_DIR/scripts/manager.sh"
source "$BASE_DIR/scripts/update.sh"
source "$BASE_DIR/scripts/templates.sh"

check_root

# --- UI Helpers ---
print_header() {
    clear
    echo -e "${CYAN}┌───────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC}  ${YELLOW}🚀 NaiveProxy & OlcRTC Ultimate Manager${NC}      ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}  ${WHITE}Версия: 2.1 | Статус: Pre-Release${NC}            ${CYAN}│${NC}"
    echo -e "${CYAN}└───────────────────────────────────────────────┘${NC}"
}

print_menu_item() {
    local key=$1
    local desc=$2
    printf "  ${GREEN}%2s)${NC} %s\n" "$key" "$desc"
}

main_menu() {
    while true; do
        print_header
        echo -e "${BLUE}--- ГЛАВНОЕ МЕНЮ ---${NC}"
        print_menu_item "1" "📦 Установка и Обновление (Система, Naive, OlcRTC)"
        print_menu_item "2" "🛡️ NaiveProxy: Пользователи и Ссылки"
        print_menu_item "3" "🚀 OlcRTC: Комнаты и Конфигурации"
        print_menu_item "4" "⚡ Оптимизация Сети и Ядра (Advanced)"
        print_menu_item "5" "🎭 Управление Маскировкой (Сайты-заглушки)"
        print_menu_item "6" "🛠️ Управление Сервисами (Status/Start/Stop)"
        print_menu_item "7" "📧 Настройка Email для отправки данных"
        print_menu_item "8" "📝 Просмотр Логов"
        print_menu_item "9" "🗑️ Удаление (Полное или Выборочное)"
        print_menu_item "0" "🚪 Выход"
        echo -e "${CYAN}─────────────────────────────────────────────────${NC}"
        read -p "Выберите опцию [0-9]: " choice

        case $choice in
            1) install_update_menu ;;
            2) naive_manager_menu ;;
            3) olcrtc_manager_menu ;;
            4) optimization_menu ;;
            5) masking_management ;;
            6) service_management ;;
            7) configure_smtp ;;
            8) view_logs ;;
            9) uninstall_menu ;;
            0) exit 0 ;;
            *) log_error "Неверный выбор" ; sleep 1 ;;
        esac
    done
}

install_update_menu() {
    while true; do
        print_header
        echo -e "${BLUE}--- УСТАНОВКА И ОБНОВЛЕНИЕ ---${NC}"
        print_menu_item "1" "Полная установка (NaiveProxy + OlcRTC)"
        print_menu_item "2" "Обновить скрипты (Repository Update)"
        print_menu_item "3" "Обновить всю систему (apt/dnf/pacman)"
        print_menu_item "4" "Обновить только NaiveProxy (Rebuild)"
        print_menu_item "5" "Обновить только OlcRTC (Rebuild)"
        print_menu_item "6" "Настроить авто-обновления (Cron)"
        print_menu_item "0" "Назад"
        echo -e "${CYAN}─────────────────────────────────────────────────${NC}"
        read -p "Выберите опцию: " o
        case $o in
            1) "$BASE_DIR/scripts/install.sh" ; read -p "Нажмите Enter..." ;;
            2) update_repo ; read -p "Нажмите Enter..." ;;
            3) update_system ; read -p "Нажмите Enter..." ;;
            4) update_naive ; read -p "Нажмите Enter..." ;;
            5) update_olcrtc ; read -p "Нажмите Enter..." ;;
            6) setup_cron_updates ; read -p "Нажмите Enter..." ;;
            0) break ;;
        esac
    done
}

naive_manager_menu() {
    while true; do
        print_header
        echo -e "${BLUE}--- МЕНЕДЖЕР NAIVEPROXY ---${NC}"
        print_menu_item "1" "➕ Добавить пользователя (Manual)"
        print_menu_item "2" "➕ Добавить пользователей (Batch)"
        print_menu_item "3" "📋 Список ссылок (Quick View)"
        print_menu_item "4" "📜 Детальная история (Date/Notes)"
        print_menu_item "5" "❌ Удалить пользователя"
        print_menu_item "6" "⚙️ Базовая настройка (Domain/Port)"
        print_menu_item "0" "Назад"
        echo -e "${CYAN}─────────────────────────────────────────────────${NC}"
        read -p "Выберите опцию: " o
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
                read -p "Количество пользователей: " count
                read -p "Общая заметка: " n
                for i in $(seq 1 $count); do
                    u=$(openssl rand -hex 4)
                    p=$(openssl rand -base64 12)
                    add_link "naive" "$u" "$p" "$n"
                done
                rebuild_caddyfile
                log_info "$count пользователей создано." ; sleep 1
                ;;
            3)
                list_links "naive" "summary"
                email_link_prompt "naive"
                read -p "Нажмите Enter..."
                ;;
            4)
                list_links "naive" "detailed"
                read -p "Нажмите Enter..."
                ;;
            5)
                read -p "ID пользователя для удаления: " sid
                delete_link "naive" "$sid"
                rebuild_caddyfile
                log_info "Удалено." ; sleep 1
                ;;
            6) configure_naive_basic ;;
            0) break ;;
        esac
    done
}

olcrtc_manager_menu() {
    while true; do
        print_header
        echo -e "${BLUE}--- МЕНЕДЖЕР OLCRTC ---${NC}"
        print_menu_item "1" "🆕 Сгенерировать новый Room ID / Key"
        print_menu_item "2" "📋 Список ссылок (olcrtc://)"
        print_menu_item "3" "📜 Детальная история (Date/Notes)"
        print_menu_item "4" "❌ Удалить Room ID"
        print_menu_item "5" "⚙️ Настроить активный сервис (Systemd)"
        print_menu_item "0" "Назад"
        echo -e "${CYAN}─────────────────────────────────────────────────${NC}"
        read -p "Выберите опцию: " o
        case $o in
            1)
                read -p "Carrier (wbstream/jazz/telemost) [wbstream]: " carr
                carr=${carr:-wbstream}
                read -p "Transport (datachannel/vp8channel) [datachannel]: " tran
                tran=${tran:-datachannel}
                room_id=$(olcrtc -mode gen -carrier "$carr" -dns 1.1.1.1:53 -amount 1 -data /opt/olcrtc/data)
                key=$(openssl rand -hex 32)
                read -p "Заметка: " n
                add_link "olcrtc" "$room_id" "$key" "$n" "$carr" "$tran"
                log_info "Room ID: $room_id сгенерирован." ; sleep 1
                ;;
            2)
                list_links "olcrtc" "summary"
                email_link_prompt "olcrtc"
                read -p "Нажмите Enter..."
                ;;
            3)
                list_links "olcrtc" "detailed"
                read -p "Нажмите Enter..."
                ;;
            4)
                read -p "Room ID для удаления: " sid
                delete_link "olcrtc" "$sid"
                log_info "Удалено." ; sleep 1
                ;;
            5) configure_olcrtc_basic ;;
            0) break ;;
        esac
    done
}

optimization_menu() {
    print_header
    echo -e "${BLUE}--- ОПТИМИЗАЦИЯ СИСТЕМЫ ---${NC}"
    print_menu_item "1" "Применить все оптимизации (BBR + Kernel + Limits)"
    print_menu_item "2" "Только BBR и Сеть"
    print_menu_item "3" "Тюнинг лимитов (File Descriptors)"
    print_menu_item "0" "Назад"
    echo -e "${CYAN}─────────────────────────────────────────────────${NC}"
    read -p "Выберите опцию: " o
    case $o in
        1) optimize_system_full ;;
        2) optimize_bbr ;;
        3) optimize_limits ;;
    esac
    read -p "Нажмите Enter..."
}

uninstall_menu() {
    print_header
    echo -e "${RED}--- УДАЛЕНИЕ СИСТЕМЫ ---${NC}"
    print_menu_item "1" "Удалить NaiveProxy (полностью)"
    print_menu_item "2" "Удалить OlcRTC (полностью)"
    print_menu_item "3" "Удалить ВСЁ (Naive + OlcRTC + Configs)"
    print_menu_item "0" "Назад"
    echo -e "${CYAN}─────────────────────────────────────────────────${NC}"
    read -p "Выберите опцию: " o
    case $o in
        1)
            read -p "Вы уверены, что хотите удалить NaiveProxy? (y/n): " confirm
            [[ $confirm == "y" ]] && bash "$BASE_DIR/scripts/uninstall.sh" --naive
            ;;
        2)
            read -p "Вы уверены, что хотите удалить OlcRTC? (y/n): " confirm
            [[ $confirm == "y" ]] && bash "$BASE_DIR/scripts/uninstall.sh" --olcrtc
            ;;
        3)
            read -p "ВНИМАНИЕ! Это удалит ВСЕ настройки и данные. Продолжить? (y/n): " confirm
            [[ $confirm == "y" ]] && bash "$BASE_DIR/scripts/uninstall.sh" --all
            ;;
    esac
    read -p "Нажмите Enter..."
}

# --- Shared UI Logic ---
configure_naive_basic() {
    read -p "Введите домен: " domain
    read -p "Введите Email для SSL: " email
    read -p "Введите порт (443): " port
    port=${port:-443}

    save_config "$domain" "$email" "$port"
    open_port "$port"
    rebuild_caddyfile
    log_info "Настройки сохранены."
    read -p "Нажмите Enter..."
}

configure_olcrtc_basic() {
    read -p "Room ID: " rid
    read -p "Client ID (default): " cid
    cid=${cid:-default}
    read -p "Key: " key
    read -p "Port (default 8080): " port
    port=${port:-8080}

    if check_port "$port"; then
        log_error "Порт $port уже занят! Выберите другой."
        read -p "Нажмите Enter..."
        return
    fi

    cp "$BASE_DIR/services/olcrtc.service" /etc/systemd/system/
    sed -i "s/ROOM_ID/$rid/g; s/CLIENT_ID/$cid/g; s/KEY/$key/g; s/PORT/$port/g" /etc/systemd/system/olcrtc.service
    mkdir -p /opt/olcrtc/data
    open_port "$port"
    systemctl daemon-reload
    log_info "OlcRTC сервис настроен на порт $port."
    read -p "Нажмите Enter..."
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

masking_management() {
    clear
    echo "--- Управление Маскировкой ---"
    echo "1) Простая загрузка (Spinner)"
    echo "2) Продвинутая загрузка (Secure Gateway)"
    echo "3) Сайт агентства недвижимости"
    echo "0) Назад"
    read -p "Выберите шаблон: " m
    case $m in
        1) apply_loading_v1 ; log_info "Применено: Loading v1" ;;
        2) apply_loading_v2 ; log_info "Применено: Secure Gateway" ;;
        3) apply_realestate ; log_info "Применено: Elite Realty" ;;
    esac
    read -p "Нажмите Enter..."
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

email_link_prompt() {
    local service=$1
    read -p "Отправить ссылку на почту? (y/n): " em
    if [[ $em == "y" ]]; then
        read -p "Введите ID (User или Room): " sid
        read -p "Email получателя: " temail
        read -p "Ваш Email (Sender) [опционально]: " semail
        process_email_send "$service" "$sid" "$temail" "$semail"
    fi
}

main_menu
