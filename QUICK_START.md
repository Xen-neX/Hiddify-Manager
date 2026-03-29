# Быстрый старт - Установка Hiddify Manager с IPv6 WARP

## Предварительные требования

Перед установкой обновите систему и установите необходимые пакеты:

```bash
sudo apt update -y
sudo apt upgrade -y
sudo apt install -y nano git apt-utils curl
```

**Требования к серверу:**
- Ubuntu 22.04+ или Debian 11+
- Минимум 1GB RAM
- 10GB свободного места
- IPv6 поддержка (опционально, для WARP IPv6)

---

## Шаг 1: Установка панели

На чистом сервере выполните:

```bash
# Скачайте и запустите установочный скрипт
curl -o install_fork.sh https://raw.githubusercontent.com/Xen-neX/Hiddify-Manager/main/install_fork.sh
chmod +x install_fork.sh
./install_fork.sh
```

Скрипт автоматически:
- Клонирует форк с исправлениями
- Установит Hiddify Manager
- Применит IPv6 WARP fix

**Время установки:** 10-15 минут

## Шаг 2: Первоначальная настройка

После установки откройте в браузере:
```
https://ВАШ_IP_АДРЕС
```

1. Создайте администратора
2. Настройте домен (опционально)
3. Включите WARP в настройках

## Шаг 3: Включение IPv6 для WARP

После того как WARP настроен и работает, включите IPv6:

```bash
cd /opt/hiddify-manager
./warp_ipv6_toggle.sh enable
```

Проверьте статус:
```bash
./warp_ipv6_toggle.sh status
```

Должно показать:
```
Status: enabled
✓ IPv6 is working: 2a09:bac1:xxxx::xxxx
```

## Готово!

Теперь у вас:
- ✅ Работающая панель Hiddify
- ✅ WARP с поддержкой IPv6
- ✅ Все исправления из форка

## Управление IPv6

```bash
# Проверить статус
./warp_ipv6_toggle.sh status

# Включить IPv6
./warp_ipv6_toggle.sh enable

# Выключить IPv6
./warp_ipv6_toggle.sh disable
```

## Обновление

Когда в форке появятся новые изменения:

```bash
cd /opt/hiddify-manager
git pull
bash common/hiddify_installer.sh release --no-gui
```

## Устранение проблем

### WARP не запускается

```bash
cd /opt/hiddify-manager/other/warp/wireguard
systemctl status wg-quick@warp
journalctl -u wg-quick@warp -n 50
```

### IPv6 не работает

```bash
# Проверьте IPv6 на хосте
curl -6 https://v6.ident.me/

# Проверьте правила маршрутизации
ip -6 rule show
ip -6 route show table 51820

# Пересоздайте конфигурацию
./warp_ipv6_toggle.sh disable
./warp_ipv6_toggle.sh enable
```

### Панель не открывается

```bash
systemctl status hiddify-panel
journalctl -u hiddify-panel -n 50
```

## Полезные команды

```bash
# Статус всех служб
systemctl status hiddify-panel
systemctl status hiddify-nginx
systemctl status wg-quick@warp

# Логи
journalctl -u hiddify-panel -f
journalctl -u wg-quick@warp -f

# Перезапуск
systemctl restart hiddify-panel
systemctl restart wg-quick@warp
```

## Поддержка

Если возникли проблемы:
- Проверьте логи выше
- Откройте issue: https://github.com/Xen-neX/Hiddify-Manager/issues
- Приложите вывод команд из раздела "Устранение проблем"
