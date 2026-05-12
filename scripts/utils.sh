#!/bin/bash

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# --- Helpers ---
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

get_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    else
        echo "unknown"
    fi
}

get_arch() {
    local arch=$(uname -m)
    case "$arch" in
        x86_64) echo "amd64" ;;
        aarch64) echo "arm64" ;;
        armv7l) echo "armv7" ;;
        *) echo "$arch" ;;
    esac
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "Пожалуйста, запустите от имени root"
        exit 1
    fi
}

# --- Port Validation ---
check_port() {
    local port=$1
    if command -v ss >/dev/null 2>&1; then
        ss -tuln | grep -q ":$port "
        return $?
    elif command -v netstat >/dev/null 2>&1; then
        netstat -tuln | grep -q ":$port "
        return $?
    fi
    return 1
}

open_port() {
    local port=$1
    if command -v ufw >/dev/null 2>&1; then
        ufw allow $port/tcp >/dev/null
    elif command -v iptables >/dev/null 2>&1; then
        iptables -I INPUT -p tcp --dport $port -j ACCEPT
    fi
}

# --- Optimizations ---
optimize_bbr() {
    log_info "Настройка BBR и TCP стека..."
    cat > /etc/sysctl.d/99-naive-bbr.conf << EOF
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
net.ipv4.tcp_fastopen=3
EOF
    sysctl -p /etc/sysctl.d/99-naive-bbr.conf >/dev/null 2>&1
}

optimize_limits() {
    log_info "Настройка лимитов (File Descriptors)..."
    cat > /etc/security/limits.d/99-naive-limits.conf << EOF
* soft nofile 1000000
* hard nofile 1000000
root soft nofile 1000000
root hard nofile 1000000
EOF
    log_info "Лимиты установлены в 1,000,000."
}

optimize_system_full() {
    log_info "Применение продвинутой оптимизации ядра..."

    cat > /etc/sysctl.d/99-naive-advanced.conf << EOF
# Kernel Network Tuning
net.core.rmem_max=67108864
net.core.wmem_max=67108864
net.core.netdev_max_backlog=65536
net.core.somaxconn=65536

# TCP Tuning
net.ipv4.tcp_rmem=4096 87380 67108864
net.ipv4.tcp_wmem=4096 65536 67108864
net.ipv4.tcp_window_scaling=1
net.ipv4.tcp_adv_win_scale=1
net.ipv4.tcp_mtu_probing=1
net.ipv4.tcp_syncookies=1
net.ipv4.tcp_tw_reuse=1
net.ipv4.tcp_fin_timeout=30
net.ipv4.tcp_keepalive_time=1200
net.ipv4.tcp_max_syn_backlog=65536
net.ipv4.tcp_max_tw_buckets=262144
net.ipv4.tcp_slow_start_after_idle=0
net.ipv4.tcp_notsent_lowat=16384

# BBR
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
EOF

    sysctl -p /etc/sysctl.d/99-naive-advanced.conf >/dev/null 2>&1
    optimize_limits
    log_info "Полная оптимизация завершена."
}
