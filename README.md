# NaiveProxy + OlcRTC: Пошаговый гайд и Авто-установщик

Этот репозиторий предоставляет максимально простое и надежное решение для развертывания связки **NaiveProxy** (маскировка под Chrome трафик) и **OlcRTC** (туннелирование через WebRTC конференции). Оптимизировано для **DietPi**, **Debian** и **Ubuntu**.

## 🚀 Быстрая установка в одну команду

Запустите этот скрипт, чтобы установить всё необходимое и открыть меню управления:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/TrapBeyond594/NaiveProxy-OlcRTC-Installer/quick-install.sh)
```

---

## 🛠 Пошаговый процесс

### 1. Подготовка
Вам понадобится:
- VPS на базе Debian (11+) или Ubuntu (22.04+).
- Привязанный поддомен (A-запись, указывающая на IP сервера).

### 2. Установка
Скрипт автоматически:
- Включит **BBR** для максимальной скорости.
- Установит зависимости (**Go**, **Mage**, **xcaddy**).
- Соберет **Caddy** с плагином NaiveProxy.
- Соберет **OlcRTC** из исходников.
- Создаст страницу-заглушку для маскировки.

### 3. Настройка через Меню
Запустите `sudo ./menu.sh` и выполните следующие шаги:
- **Пункт 2**: Настройте домен, Email (для SSL) и учетные данные NaiveProxy.
- **Пункт 3**: Настройте OlcRTC (Room ID и Ключ).
- **Пункт 4**: Запустите оба сервиса.

---

## 📱 Список клиентов

| Платформа | Клиент | Ссылка |
| :--- | :--- | :--- |
| **Android** | NekoBox | [GitHub](https://github.com/MatsuriDayo/NekoBoxForAndroid/releases) |
| **iOS** | Karing | [App Store](https://apps.apple.com/app/karing/id6472431552) |
| **Windows** | v2rayN | [GitHub](https://github.com/2dust/v2rayN/releases) |
| **MacOS** | NekoBox | [GitHub](https://github.com/MatsuriDayo/nekoray/releases) |

---

## 💡 Полезные команды

- `sudo ./menu.sh` — открыть меню управления.
- `journalctl -u caddy -f` — логи NaiveProxy в реальном времени.
- `journalctl -u olcrtc -f` — логи OlcRTC в реальном времени.
- `systemctl restart caddy` — перезапуск NaiveProxy.

---

## 🛡 Безопасность и стабильность
- **Systemd**: Автоматический перезапуск сервисов при падении.
- **UFW/iptables**: Автоматическая настройка брандмауэра.
- **Маскировка**: Полноценный TLS сертификат и HTML-заглушка на порту 443.

---
*Сделано для свободы интернета. Опирается на наработки [klzgrad](https://github.com/klzgrad/naiveproxy) и [openlibrecommunity](https://github.com/openlibrecommunity/olcrtc).*
