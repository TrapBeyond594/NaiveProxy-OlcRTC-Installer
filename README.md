# 🛡️ NaiveProxy + OlcRTC Installer & Manager v2.0

![License](https://img.shields.io/github/license/TrapBeyond594/New-Repository?style=flat-square)
![Version](https://img.shields.io/badge/version-2.0-blue?style=flat-square)
![Platform](https://img.shields.io/badge/platform-Linux-lightgrey?style=flat-square)

Универсальный инструмент для автоматической установки, настройки и управления **NaiveProxy** и **OlcRTC** на большинстве дистрибутивов Linux.

---

## ✨ Основные возможности

- **🌍 Кроссплатформенность**: Поддержка Debian, Ubuntu, DietPi, CentOS, Fedora и Arch Linux.
- **🚀 Максимальная скорость**: Автоматическая настройка BBR и глубокая оптимизация TCP стека.
- **👥 Multi-User**: Генерация неограниченного количества ссылок для NaiveProxy и OlcRTC с заметками.
- **📅 История и Менеджмент**: Удобная вкладка со всеми созданными ссылками, датой создания и управлением.
- **📧 Отправка на Email**: Возможность отправить настройки прямо в клиент через почту.
- **🔄 Авто-обновления**: Встроенная проверка обновлений репозитория и системы.
- **🏗️ Самодостаточность**: Сборка бинарников без лишних зависимостей.
- **🗑️ Полное удаление**: Функция удаления "с корнями" одним нажатием.

---

## 🚀 Быстрый запуск

Запустите команду для установки и открытия интерактивного меню:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/TrapBeyond594/NaiveProxy-OlcRTC-Installer/main/quick-install.sh)
```

Или вручную:
```bash
git clone https://github.com/TrapBeyond594/New-Repository.git
cd New-Repository
chmod +x menu.sh
sudo ./menu.sh
```

---

## 📱 Клиентские приложения

### 🔹 NaiveProxy
| Платформа | Клиент | Ссылка |
| :--- | :--- | :--- |
| **Android** | NekoBox | [GitHub](https://github.com/MatsuriDayo/NekoBoxForAndroid/releases) |
| **iOS** | Karing | [App Store](https://apps.apple.com/app/karing/id6472431552) |
| **Windows** | v2rayN | [GitHub](https://github.com/2dust/v2rayN/releases) |
| **MacOS** | NekoBox | [GitHub](https://github.com/MatsuriDayo/nekoray/releases) |

### 🔹 OlcRTC (OlcBox)
| Платформа | Ссылка на скачивание (Nightly) |
| :--- | :--- |
| **Android** | [Olcbox.apk](https://github.com/alananisimov/olcbox/releases/download/nightly/Olcbox-android-release.apk) |
| **Windows** | [Olcbox.exe](https://github.com/alananisimov/olcbox/releases/download/nightly/Olcbox-windows-amd64.exe) |
| **MacOS** | [Olcbox.dmg](https://github.com/alananisimov/olcbox/releases/download/nightly/Olcbox-macos.dmg) |
| **Linux** | [Olcbox.AppImage](https://github.com/alananisimov/olcbox/releases/download/nightly/Olcbox-linux-amd64.AppImage) |

---

## 🛠️ Управление

Все действия выполняются через удобное меню:
`sudo ./menu.sh`

1. **Установка**: Автоматическая сборка всех компонентов.
2. **NaiveProxy**: Добавление пользователей, генерация ссылок `naive+https://`, просмотр списка.
3. **OlcRTC**: Генерация Room ID и ключей, управление списком.
4. **Обновления**: Проверка обновлений скриптов и системных пакетов.
5. **Оптимизация**: Применение продвинутых сетевых настроек для обхода блокировок и ускорения.

---
*Разработано для обеспечения свободы и конфиденциальности в сети.*
