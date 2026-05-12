# 🛡️ NaiveProxy + OlcRTC Ultimate Installer & Manager

![License](https://img.shields.io/github/license/TrapBeyond594/New-Repository?style=flat-square)
![Version](https://img.shields.io/badge/version-2.1-blue?style=flat-square)
![Platform](https://img.shields.io/badge/platform-Linux-lightgrey?style=flat-square)

Профессиональное решение для автоматизации развертывания и управления высокопроизводительными прокси-сервисами **NaiveProxy** и SFU-коммуникациями **OlcRTC**.

---

## 💎 Особенности (Features)

- **🚀 Extreme Performance**: Автоматический тюнинг ядра, TCP стека и активация BBR для минимальных задержек.
- **👥 Advanced Multi-User**: Генерация неограниченного числа ссылок с привязкой к дате и заметкам.
- **🔄 Интеллектуальное Обновление**: Отдельное обновление системы, репозитория и каждого сервиса (с пересборкой из исходников).
- **🛡️ Скрытность**: Встроенные шаблоны сайтов-заглушек (Elite Realty, Secure Gateway) для маскировки трафика.
- **📱 Полная Совместимость**: Поддержка всех популярных дистрибутивов (Debian, Ubuntu, Arch, CentOS, Fedora).
- **📧 Email Дистрибуция**: Отправка конфигурационных ссылок прямо на почту пользователям.
- **🗑️ Чистое Удаление**: Возможность выборочного или полного удаления всех компонентов системы.

---

## 🚀 Быстрый запуск (Quick Start)

Выполните одну команду для установки и запуска интерактивного меню:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/TrapBeyond594/New-Repository/main/quick-install.sh)
```

Или установите вручную:
```bash
git clone https://github.com/TrapBeyond594/New-Repository.git
cd New-Repository
chmod +x menu.sh
sudo ./menu.sh
```

---

## 📱 Клиентские приложения (Clients)

### 🔹 NaiveProxy
| Платформа | Клиент | Ссылка |
| :--- | :--- | :--- |
| **Android** | NekoBox | [Скачать с GitHub](https://github.com/MatsuriDayo/NekoBoxForAndroid/releases) |
| **iOS** | Karing | [App Store](https://apps.apple.com/app/karing/id6472431552) |
| **Windows** | v2rayN | [Скачать с GitHub](https://github.com/2dust/v2rayN/releases) |
| **MacOS** | NekoBox | [Скачать с GitHub](https://github.com/MatsuriDayo/nekoray/releases) |

### 🔹 OlcRTC (OlcBox)
| Платформа | Прямая ссылка (Nightly) |
| :--- | :--- |
| **Android** | [Olcbox-android-release.apk](https://github.com/alananisimov/olcbox/releases/download/nightly/Olcbox-android-release.apk) |
| **Windows** | [Olcbox-windows-amd64.exe](https://github.com/alananisimov/olcbox/releases/download/nightly/Olcbox-windows-amd64.exe) |
| **MacOS** | [Olcbox-macos.dmg](https://github.com/alananisimov/olcbox/releases/download/nightly/Olcbox-macos.dmg) |
| **iOS** | [TestFlight / Manual](https://github.com/alananisimov/olcbox/releases) |
| **Linux** | [Olcbox-linux-amd64.AppImage](https://github.com/alananisimov/olcbox/releases/download/nightly/Olcbox-linux-amd64.AppImage) |

---

## 🛠️ Структура управления

Запустите `sudo ./menu.sh` для доступа к разделам:

1. **📦 Install/Update**: Управление версиями и системными пакетами.
2. **🛡️ NaiveProxy**: Управление пользователями, генерация `naive+https://` ссылок.
3. **🚀 OlcRTC**: Генерация Room ID, настройка SFU портов и `olcrtc://` ссылок.
4. **⚡ Optimization**: Применение сетевого тюнинга "в один клик".
5. **📧 Email**: Настройка SMTP для рассылки доступов.

---
*Created for Privacy and Performance.*
