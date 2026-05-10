#!/bin/bash
source "$(dirname "$0")/utils.sh"

install_base_deps() {
    log_info "Установка базовых зависимостей..."
    local os=$(get_os)
    case "$os" in
        debian|ubuntu|dietpi|raspbian)
            apt-get update
            apt-get install -y curl git build-essential ufw wget openssl
            ;;
        *)
            log_warn "Неподдерживаемая ОС для автоматической установки пакетов. Попробуйте установить curl, git, build-essential, ufw вручную."
            ;;
    esac
}

install_go() {
    if command -v go >/dev/null 2>&1; then
        local version=$(go version | awk '{print $3}' | sed 's/go//')
        if [[ "$(printf '%s\n' "1.26.0" "$version" | sort -V | head -n1)" == "1.26.0" ]]; then
            log_info "Go $version уже установлен."
            return
        fi
    fi

    log_info "Установка Go 1.26.0..."
    local arch=$(get_arch)
    local go_arch=""
    case "$arch" in
        amd64) go_arch="amd64" ;;
        arm64) go_arch="arm64" ;;
        armv7) go_arch="armv6l" ;;
        *) log_error "Неподдерживаемая архитектура для Go: $arch"; return 1 ;;
    esac

    wget https://go.dev/dl/go1.26.0.linux-$go_arch.tar.gz
    rm -rf /usr/local/go && tar -C /usr/local -xzf go1.26.0.linux-$go_arch.tar.gz
    rm go1.26.0.linux-$go_arch.tar.gz

    ln -sf /usr/local/go/bin/go /usr/bin/go
    ln -sf /usr/local/go/bin/gofmt /usr/bin/gofmt

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
    mkdir -p /var/www/html

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

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    check_root
    install_base_deps
    install_go
    install_mage
    install_caddy_naive
    install_olcrtc
fi
