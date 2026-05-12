#!/bin/bash
source "$(dirname "$0")/utils.sh"

install_base_deps() {
    log_info "Установка базовых зависимостей..."
    local os=$(get_os)
    case "$os" in
        debian|ubuntu|dietpi|raspbian)
            apt-get update
            apt-get install -y curl git build-essential ufw wget openssl jq msmtp
            ;;
        fedora|centos)
            dnf groupinstall -y "Development Tools"
            dnf install -y ufw wget openssl jq msmtp
            ;;
        arch)
            pacman -Sy --noconfirm base-devel ufw wget openssl jq msmtp
            ;;
        *)
            log_warn "Неподдерживаемая ОС ($os). Попробуйте установить зависимости вручную."
            ;;
    esac
}

install_go() {
    log_info "Проверка последней версии Go..."
    local latest_version=$(curl -fsSL 'https://go.dev/VERSION?m=text' | head -n1)

    if command -v go >/dev/null 2>&1; then
        local current_version=$(go version | awk '{print $3}')
        if [[ "$current_version" == "$latest_version" ]]; then
            log_info "Go $current_version уже установлен (актуальная версия)."
            return
        fi
    fi

    log_info "Установка $latest_version..."
    local arch=$(get_arch)
    local go_arch=""
    case "$arch" in
        amd64) go_arch="amd64" ;;
        arm64) go_arch="arm64" ;;
        armv7) go_arch="armv6l" ;;
        *) log_error "Неподдерживаемая архитектура для Go: $arch"; return 1 ;;
    esac

    wget "https://go.dev/dl/${latest_version}.linux-${go_arch}.tar.gz" -O /tmp/go.tar.gz
    rm -rf /usr/local/go && tar -C /usr/local -xzf /tmp/go.tar.gz
    rm /tmp/go.tar.gz

    ln -sf /usr/local/go/bin/go /usr/bin/go
    ln -sf /usr/local/go/bin/gofmt /usr/bin/gofmt

    # Ensure Go binaries are in PATH for root and future sessions
    if ! grep -q "/usr/local/go/bin" /root/.profile; then
        echo 'export PATH=$PATH:/usr/local/go/bin' >> /root/.profile
    fi

    log_info "Go успешно установлен: $(go version)"
}

install_mage() {
    if command -v mage >/dev/null 2>&1; then
        log_info "Mage уже установлен."
        return
    fi

    log_info "Установка Mage..."
    export GOPATH=$HOME/go
    export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin

    go install github.com/magefile/mage@latest
    cp $GOPATH/bin/mage /usr/local/bin/mage

    if ! grep -q "$GOPATH/bin" /root/.profile; then
        echo 'export PATH=$PATH:$GOPATH/bin' >> /root/.profile
    fi

    log_info "Mage успешно установлен: $(mage -version)"
}

install_caddy_naive() {
    log_info "Установка Caddy с плагином naive..."
    if command -v caddy >/dev/null 2>&1; then
        log_info "Caddy уже установлен."
        return
    fi

    log_info "Установка xcaddy для сборки Caddy..."
    export GOPATH=$HOME/go
    export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin
    go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest

    log_info "Сборка Caddy с forwardproxy..."
    $GOPATH/bin/xcaddy build --with github.com/caddyserver/forwardproxy@master=github.com/klzgrad/forwardproxy@naive

    mv caddy /usr/local/bin/caddy
    chmod +x /usr/local/bin/caddy

    mkdir -p /etc/caddy
    setup_dummy_page

    log_info "Caddy успешно установлен."
}

install_olcrtc() {
    log_info "Установка OlcRTC..."
    if command -v olcrtc >/dev/null 2>&1; then
        log_info "OlcRTC уже установлен."
        return
    fi

    mkdir -p /opt
    cd /opt
    if [ ! -d "olcrtc" ]; then
        git clone https://github.com/openlibrecommunity/olcrtc --recurse-submodules
    fi
    cd olcrtc

    export GOPATH=$HOME/go
    export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin

    log_info "Сборка OlcRTC..."
    mage buildCLI

    local arch=$(get_arch)
    local bin_name="olcrtc-linux-$arch"
    if [ -f "build/$bin_name" ]; then
        cp "build/$bin_name" /usr/local/bin/olcrtc
        chmod +x /usr/local/bin/olcrtc
        log_info "OlcRTC успешно установлен."
    else
        log_error "Бинарный файл OlcRTC не найден после сборки."
        return 1
    fi
}

cleanup_build_deps() {
    log_info "Очистка зависимостей сборки..."
    rm -rf /usr/local/go
    rm -rf "$HOME/go"
    log_info "Очистка завершена."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    check_root
    install_base_deps
    optimize_system
    install_go
    install_mage
    install_caddy_naive
    install_olcrtc

    read -p "Удалить зависимости сборки (Go, Mage, xcaddy)? (y/n): " cleanup
    if [[ $cleanup == "y" ]]; then
        cleanup_build_deps
    fi

    log_info "Установка завершена! Теперь запустите ./menu.sh для настройки."
fi
