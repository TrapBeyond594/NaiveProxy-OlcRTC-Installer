#!/bin/bash

# Simple installer that clones the repo and runs the script
# This allows the "curl | bash" one-liner to work correctly with multi-file projects.

REPO_URL="https://github.com/your-username/your-repo-name.git"
INSTALL_DIR="/opt/naive-olcrtc"

if [ "$EUID" -ne 0 ]; then
    echo "Пожалуйста, запустите от имени root (sudo bash ...)"
    exit 1
fi

echo "--- Инициализация установки ---"
apt-get update && apt-get install -y git

if [ -d "$INSTALL_DIR" ]; then
    echo "Обновление существующей установки..."
    cd "$INSTALL_DIR" && git pull
else
    echo "Клонирование репозитория..."
    git clone "$REPO_URL" "$INSTALL_DIR"
    cd "$INSTALL_DIR"
fi

chmod +x menu.sh scripts/*.sh

# Run the actual install logic
./scripts/install.sh

echo "--- Установка завершена ---"
echo "Теперь вы можете запустить меню управления командой:"
echo "cd $INSTALL_DIR && sudo ./menu.sh"
