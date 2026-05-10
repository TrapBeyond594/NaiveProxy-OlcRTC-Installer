#!/bin/bash

# Detect OS
get_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    else
        echo "unknown"
    fi
}

# Detect Architecture
get_arch() {
    local arch=$(uname -m)
    case "$arch" in
        x86_64) echo "amd64" ;;
        aarch64) echo "arm64" ;;
        armv7l) echo "armv7" ;;
        *) echo "$arch" ;;
    esac
}

# Check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "Пожалуйста, запустите от имени root"
        exit 1
    fi
}

enable_bbr() {
    log_info "Включение BBR..."
    if sysctl net.ipv4.tcp_congestion_control | grep -q "bbr"; then
        log_info "BBR уже включен."
        return
    fi
    echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
    sysctl -p
    if sysctl net.ipv4.tcp_congestion_control | grep -q "bbr"; then
        log_info "BBR успешно включен."
    else
        log_error "Не удалось включить BBR."
    fi
}

setup_dummy_page() {
    log_info "Создание страницы-заглушки..."
    mkdir -p /var/www/html
    cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html><html><head><meta charset="utf-8"><title>Loading</title><style>body{background:linear-gradient(135deg,#0f172a,#1e293b);height:100vh;margin:0;display:flex;flex-direction:column;align-items:center;justify-content:center;font-family:sans-serif}.spinner{width:40px;height:40px;border-radius:50%;border:3px solid rgba(255,255,255,0.12);border-top-color:#38bdf8;animation:spin 0.8s linear infinite;margin-bottom:25px;box-shadow:0 0 18px rgba(56,189,248,0.25)}@keyframes spin{to{transform:rotate(360deg)}}.t{color:#cbd5e1;font-size:13px;letter-spacing:3px;font-weight:600}</style></head><body><div class="spinner"></div><div class="t">CONNECTING</div></body></html>
EOF
}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if port is in use
check_port() {
    local port=$1
    if command -v lsof >/dev/null 2>&1; then
        lsof -i :$port > /dev/null
        return $?
    elif command -v netstat >/dev/null 2>&1; then
        netstat -tuln | grep -q ":$port "
        return $?
    fi
    return 1 # Assume not in use if we can't check
}

# Configure Firewall
open_port() {
    local port=$1
    if command -v ufw >/dev/null 2>&1; then
        ufw allow $port/tcp
        log_info "Брандмауэр: порт $port открыт (UFW)"
    elif command -v iptables >/dev/null 2>&1; then
        iptables -I INPUT -p tcp --dport $port -j ACCEPT
        log_info "Брандмауэр: порт $port открыт (iptables)"
    fi
}
