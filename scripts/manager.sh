#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

DB_FILE="/etc/naive-olcrtc/links.json"
CONFIG_FILE="/etc/naive-olcrtc/config.json"

[ ! -d "/etc/naive-olcrtc" ] && mkdir -p /etc/naive-olcrtc
[ ! -f "$DB_FILE" ] && echo "[]" > "$DB_FILE"
[ ! -f "$CONFIG_FILE" ] && echo "{}" > "$CONFIG_FILE"

# --- Config ---
save_config() {
    jq -n --arg d "$1" --arg e "$2" --arg p "$3" '{"domain": $d, "email": $e, "port": $p}' > "$CONFIG_FILE"
}

get_config() {
    jq -r ".$1 // \"\"" "$CONFIG_FILE"
}

# --- Links ---
add_link() {
    local service=$1 id=$2 pass=$3 note=$4 carr=${5:-""} tran=${6:-""}
    local date=$(date +"%Y-%m-%d %H:%M:%S")
    jq --arg svc "$service" --arg id "$id" --arg pass "$pass" --arg note "$note" --arg date "$date" --arg carr "$carr" --arg tran "$tran" \
       '. += [{"service": $svc, "id": $id, "password": $pass, "note": $note, "date": $date, "carrier": $carr, "transport": $tran}]' \
       "$DB_FILE" > "$DB_FILE.tmp" && mv "$DB_FILE.tmp" "$DB_FILE"
}

list_links() {
    local service=$1 mode=$2
    echo -e "${CYAN}─────────────────────────────────────────────────${NC}"
    if [[ $mode == "detailed" ]]; then
        printf "${YELLOW}%-15s | %-19s | %s${NC}\n" "ID/Room" "Дата" "Заметка"
        echo "-------------------------------------------------"
        jq -r ".[] | select(.service == \"$service\") | \"\(.id)|\(.date)|\(.note)\"" "$DB_FILE" | while IFS='|' read -r i d n; do
            printf "%-15s | %-19s | %s\n" "$i" "$d" "$n"
        done
    else
        printf "${YELLOW}%-15s | %-10s | %s${NC}\n" "ID" "Заметка" "Ссылка"
        echo "-------------------------------------------------"
        if [[ $service == "naive" ]]; then
            local dom=$(get_config "domain") port=$(get_config "port")
            jq -r ".[] | select(.service == \"naive\") | \"\(.id)|\(.note)|\(.password)\"" "$DB_FILE" | while IFS='|' read -r i n p; do
                printf "%-15s | %-10s | naive+https://%s:%s@%s:%s\n" "$i" "$n" "$i" "$p" "$dom" "$port"
            done
        else
            jq -c ".[] | select(.service == \"olcrtc\")" "$DB_FILE" | while IFS= read -r row; do
                local i=$(echo "$row" | jq -r '.id')
                local n=$(echo "$row" | jq -r '.note')
                local p=$(echo "$row" | jq -r '.password')
                local c=$(echo "$row" | jq -r '.carrier')
                local t=$(echo "$row" | jq -r '.transport')
                local u=$(generate_olcrtc_uri "$c" "$t" "$i" "$p")
                printf "%-15s | %-10s | %s\n" "$i" "$n" "$u"
            done
        fi
    fi
    echo -e "${CYAN}─────────────────────────────────────────────────${NC}"
}

generate_olcrtc_uri() {
    echo "olcrtc://$1?$2@$3#$4%default\$direct"
}

delete_link() {
    jq "del(.[] | select(.service == \"$1\" and .id == \"$2\"))" "$DB_FILE" > "$DB_FILE.tmp" && mv "$DB_FILE.tmp" "$DB_FILE"
}

# --- Service Logic ---
rebuild_caddyfile() {
    local dom=$(get_config "domain") email=$(get_config "email") port=$(get_config "port")
    [ -z "$dom" ] && return

    local auth_lines=""
    while IFS='|' read -r u p; do
        if [[ -n "$u" && -n "$p" ]]; then
            auth_lines+="        basic_auth $u $p"$'\n'
        fi
    done <<< "$(jq -r '.[] | select(.service == "naive") | "\(.id)|\(.password)"' "$DB_FILE")"

    cat > /etc/caddy/Caddyfile << EOF
{
    order forward_proxy before file_server
}
$dom:$port {
    tls $email
    forward_proxy {
$auth_lines
        hide_ip
        hide_via
        probe_resistance
    }
    file_server { root /var/www/html }
}
EOF
    systemctl restart caddy 2>/dev/null || systemctl restart naiveproxy 2>/dev/null
}

# --- Email ---
process_email_send() {
    local svc=$1 id=$2 to=$3 from=$4
    local data=$(jq -r ".[] | select(.service == \"$svc\" and .id == \"$id\")" "$DB_FILE")
    [ -z "$data" ] && { log_error "Данные не найдены"; return; }

    local body=""
    if [[ $svc == "naive" ]]; then
        local dom=$(get_config "domain") port=$(get_config "port")
        local p=$(echo "$data" | jq -r '.password')
        body=$(printf "Ваша ссылка NaiveProxy:\nnaive+https://%s:%s@%s:%s" "$id" "$p" "$dom" "$port")
    else
        local p=$(echo "$data" | jq -r '.password')
        local c=$(echo "$data" | jq -r '.carrier')
        local t=$(echo "$data" | jq -r '.transport')
        local uri=$(generate_olcrtc_uri "$c" "$t" "$id" "$p")
        body=$(printf "Ваша ссылка OlcRTC:\n%s" "$uri")
    fi

    # Handle temporary sender
    local config_file="$HOME/.msmtprc"
    if [[ -n "$from" ]]; then
        sed -i "s/^from .*/from $from/" "$config_file"
    fi

    if command -v msmtp >/dev/null 2>&1; then
        echo -e "Subject: $svc Config - $id\n\n$body" | msmtp "$to"
        log_info "Отправлено на $to"
    else
        log_warn "msmtp не установлен. Ссылка:\n$body"
    fi
}
