#!/bin/bash

# Simple installer that clones the repo and runs the script
# This allows the "curl | bash" one-liner to work correctly with multi-file projects.

REPO_URL="https://github.com/TrapBeyond594/New-Repository.git"
INSTALL_DIR="/opt/naive-olcrtc"

if [ "$EUID" -ne 0 ]; then
    echo "Пожалуйста, запустите от имени root (sudo bash ...)"
    exit 1
fi

echo "--- Инициализация установки ---"

# Detect OS and install git
if command -v apt-get >/dev/null; then
    apt-get update && apt-get install -y git
elif command -v dnf >/dev/null; then
    dnf install -y git
elif command -v pacman >/dev/null; then
    pacman -Sy --noconfirm git
fi

if [ -d "$INSTALL_DIR" ]; then
    echo "Обновление существующей установки..."
    cd "$INSTALL_DIR" && git pull
else
    echo "Клонирование репозитория..."
    git clone "$REPO_URL" "$INSTALL_DIR"
    cd "$INSTALL_DIR"
fi

chmod +x menu.sh
chmod +x scripts/*.sh

# Run the actual install logic
./scripts/install.sh

echo "--- Установка завершена ---"
echo "Теперь вы можете запустить меню управления командой:"
echo "cd $INSTALL_DIR && sudo ./menu.sh"
