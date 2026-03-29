# 🎯 Hiddify Manager - IPv6 WARP Fix Fork

Это форк [Hiddify Manager](https://github.com/hiddify/Hiddify-Manager) с исправлением для работы IPv6 через WARP.

## ✨ Что исправлено

В оригинальной версии IPv6 не работал через WARP, даже если был доступен на хосте. Этот форк решает проблему:

- ✅ **IPv6 работает через WARP**
- ✅ Правильная проверка доступности IPv6 (с флагом `-6`)
- ✅ Policy-based routing для IPv6 трафика
- ✅ Автоматическое добавление правил маршрутизации
- ✅ Простое управление через скрипт

## 🚀 Быстрая установка

### Предварительные требования

```bash
sudo apt update -y
sudo apt upgrade -y
sudo apt install -y nano git apt-utils curl
```

### Установка

```bash
curl -o install_fork.sh https://raw.githubusercontent.com/Xen-neX/Hiddify-Manager/main/install_fork.sh
chmod +x install_fork.sh
./install_fork.sh
```

После установки:
1. Откройте панель: `https://ВАШ_IP`
2. Включите WARP в настройках
3. Включите IPv6: `./warp_ipv6_toggle.sh enable`

## 📚 Документация

- **[Быстрый старт](QUICK_START.md)** - пошаговая установка
- **[Подробная документация](README_IPv6_FIX.md)** - технические детали
- **[Установка форка](INSTALL_FORK.md)** - разные способы установки
- **[Техническое описание](WARP_IPV6_FIX.md)** - как работает исправление

## 🔧 Управление IPv6

```bash
# Включить IPv6
./warp_ipv6_toggle.sh enable

# Выключить IPv6
./warp_ipv6_toggle.sh disable

# Проверить статус
./warp_ipv6_toggle.sh status
```

## 🔍 Проверка работы

```bash
# Проверить IPv6 через WARP
curl -6 --interface warp https://v6.ident.me/

# Должен показать IPv6 адрес Cloudflare WARP
```

## 📝 Изменённые файлы

1. `other/warp/wireguard/run.sh.j2` - добавлены правила IPv6 маршрутизации
2. `other/warp/singbox/run.sh` - исправлена проверка IPv6
3. `warp_ipv6_toggle.sh` - новый скрипт управления IPv6
4. `install_fork.sh` - скрипт установки форка
5. `fix_warp_ipv6.sh` - автоматическое применение исправления

## 🛠️ Техническое решение

Добавлены правила policy-based routing для IPv6:

```bash
PostUp = ip -6 route add default dev warp table 51820
PostUp = ip -6 rule add from <ipv6_addr> table 51820 pref 1000
PostUp = ip -6 rule add oif warp table 51820 pref 999  # ← ключевое правило!
```

Правило `oif warp` обеспечивает маршрутизацию всего исходящего IPv6 трафика через интерфейс WARP.

## 🔄 Обновление

```bash
cd /opt/hiddify-manager
git pull
./warp_ipv6_toggle.sh enable
```

## 🐛 Проблемы?

- [Открыть issue](https://github.com/Xen-neX/Hiddify-Manager/issues)
- [Документация по устранению проблем](README_IPv6_FIX.md#устранение-проблем)

## 🙏 Благодарности

- Команде [Hiddify](https://github.com/hiddify) за отличную панель
- Сообществу за тестирование

## 📜 Лицензия

Как и оригинальный Hiddify Manager - см. [LICENSE](LICENSE)

---

**Оригинальный репозиторий:** https://github.com/hiddify/Hiddify-Manager

**Этот форк:** https://github.com/Xen-neX/Hiddify-Manager
