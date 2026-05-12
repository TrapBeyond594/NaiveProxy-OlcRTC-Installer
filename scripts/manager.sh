#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

DB_FILE="/etc/naive-olcrtc/links.json"
CONFIG_FILE="/etc/naive-olcrtc/config.json"

if [ ! -d "/etc/naive-olcrtc" ]; then
    mkdir -p /etc/naive-olcrtc
fi

if [ ! -f "$DB_FILE" ]; then
    echo "[]" > "$DB_FILE"
fi

if [ ! -f "$CONFIG_FILE" ]; then
    echo "{}" > "$CONFIG_FILE"
fi

# Configuration Management
save_config() {
    local domain=$1
    local email=$2
    local port=$3
    jq -n --arg d "$domain" --arg e "$email" --arg p "$port" '{"domain": $d, "email": $e, "port": $p}' > "$CONFIG_FILE"
}

get_config() {
    local key=$1
    jq -r ".$key // \"\"" "$CONFIG_FILE"
}

# Link Management
add_link() {
    local service=$1
    local id=$2
    local password=$3
    local note=$4
    local date=$(date +"%Y-%m-%d %H:%M:%S")

    jq ". += [{\"service\": \"$service\", \"id\": \"$id\", \"password\": \"$password\", \"note\": \"$note\", \"date\": \"$date\"}]" "$DB_FILE" > "$DB_FILE.tmp" && mv "$DB_FILE.tmp" "$DB_FILE"
}

list_links() {
    local service=$1
    echo -e "${YELLOW}ID | Date | Note | Password/Key${NC}"
    echo "---------------------------------------------------------------"
    jq -r ".[] | select(.service == \"$service\") | \"\(.id) | \(.date) | \(.note) | \(.password)\"" "$DB_FILE"
}

delete_link() {
    local service=$1
    local id=$2
    jq "del(.[] | select(.service == \"$service\" and .id == \"$id\"))" "$DB_FILE" > "$DB_FILE.tmp" && mv "$DB_FILE.tmp" "$DB_FILE"
}

# NaiveProxy Caddyfile rebuilder
rebuild_caddyfile() {
    local domain=$(get_config "domain")
    local email=$(get_config "email")
    local port=$(get_config "port")

    if [[ -z "$domain" || -z "$port" ]]; then
        log_error "Конфигурация NaiveProxy не найдена. Сначала выполните настройку."
        return
    fi

    # Get all naive users from DB
    local users_json=$(jq -c '.[] | select(.service == "naive")' "$DB_FILE")

    local auth_block=""
    while IFS= read -r user; do
        [ -z "$user" ] && continue
        local u=$(echo "$user" | jq -r '.id')
        local p=$(echo "$user" | jq -r '.password')
        auth_block+="        basic_auth $u $p\n"
    done <<< "$users_json"

    cat > /etc/caddy/Caddyfile << EOF
{
    order forward_proxy before file_server
}
$domain:$port {
    tls $email
    forward_proxy {
$auth_block
        hide_ip
        hide_via
        probe_resistance
    }
    file_server {
        root /var/www/html
    }
}
EOF
    if systemctl is-active --quiet caddy; then
        caddy reload --config /etc/caddy/Caddyfile --adapter caddyfile >/dev/null 2>&1
    elif systemctl is-active --quiet naiveproxy; then
        systemctl restart naiveproxy
    else
        systemctl start caddy 2>/dev/null || systemctl start naiveproxy
    fi
}

# Email function
send_link_email() {
    local to_email=$1
    local subject=$2
    local body=$3

    if command -v msmtp >/dev/null 2>&1; then
        echo -e "Subject: $subject\n\n$body" | msmtp "$to_email"
        log_info "Ссылка отправлена на $to_email"
    else
        log_warn "msmtp не настроен. Пожалуйста, отправьте ссылку вручную:"
        echo "$body"
    fi
}
