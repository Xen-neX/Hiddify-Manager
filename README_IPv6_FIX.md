# Hiddify Manager - IPv6 WARP Fix

Этот форк Hiddify Manager содержит исправление для работы IPv6 через WARP.

## Проблема

В оригинальной версии Hiddify Manager IPv6 не работал через WARP, даже если IPv6 был доступен на хосте. Причины:

1. **Неправильная проверка IPv6**: `curl` без флага `-6` мог подключаться через IPv4
2. **Отсутствие маршрутизации**: Не было правил policy-based routing для IPv6 трафика через интерфейс WARP

## Решение

Добавлены:
- Правильная проверка IPv6 с флагом `-6`
- Policy-based routing для IPv6:
  - Отдельная таблица маршрутизации (51820)
  - Правило для трафика с адреса WARP
  - **Ключевое правило `oif warp`** для всего исходящего трафика

## Быстрая установка

### Предварительные требования

```bash
sudo apt update -y
sudo apt upgrade -y
sudo apt install -y nano git apt-utils curl
```

### Шаг 1: Установка Hiddify Manager

```bash
curl -o install_fork.sh https://raw.githubusercontent.com/Xen-neX/Hiddify-Manager/main/install_fork.sh
chmod +x install_fork.sh
./install_fork.sh
```

### Шаг 2: Настройка панели

1. Откройте `https://ВАШ_IP` в браузере
2. Создайте администратора
3. Включите WARP в настройках панели
4. Дождитесь установки WARP (1-2 минуты)

### Шаг 3: Включение IPv6

```bash
cd /opt/hiddify-manager
./warp_ipv6_toggle.sh enable
```

Проверка:
```bash
./warp_ipv6_toggle.sh status
```

## Управление IPv6

### Включить IPv6
```bash
./warp_ipv6_toggle.sh enable
```

### Выключить IPv6
```bash
./warp_ipv6_toggle.sh disable
```

### Проверить статус
```bash
./warp_ipv6_toggle.sh status
```

## Проверка работы

```bash
# Проверить IPv6 через WARP
curl -6 --interface warp https://v6.ident.me/

# Проверить правила маршрутизации
ip -6 rule show
ip -6 route show table 51820

# Проверить конфигурацию WARP
cat /etc/wireguard/warp.conf | grep "oif warp"
```

## Технические детали

### Измененные файлы

1. **`other/warp/wireguard/run.sh.j2`**
   - Добавлен флаг `-6` для проверки IPv6
   - Добавлены PostUp/PostDown правила для IPv6 маршрутизации

2. **`other/warp/singbox/run.sh`**
   - Добавлен флаг `-6` для проверки IPv6

### Правила маршрутизации

При включении IPv6 добавляются следующие правила в `/etc/wireguard/warp.conf`:

```bash
PostUp = ip -6 route add default dev warp table 51820
PostUp = ip -6 rule add from 2606:4700:110:xxxx:xxxx:xxxx:xxxx:xxxx/128 table 51820 pref 1000
PostUp = ip -6 rule add oif warp table 51820 pref 999
PostDown = ip -6 rule del oif warp table 51820 pref 999
PostDown = ip -6 rule del from 2606:4700:110:xxxx:xxxx:xxxx:xxxx:xxxx/128 table 51820 pref 1000
PostDown = ip -6 route del default dev warp table 51820
```

**Ключевое правило**: `ip -6 rule add oif warp table 51820 pref 999`

Это правило обеспечивает маршрутизацию всего исходящего IPv6 трафика через интерфейс WARP, что необходимо для работы с `bind_interface` в Xray/Sing-box.

## Устранение проблем

### IPv6 не работает после включения

```bash
# 1. Проверьте IPv6 на хосте
curl -6 https://v6.ident.me/

# 2. Проверьте статус WARP
systemctl status wg-quick@warp

# 3. Проверьте правила
ip -6 rule show | grep warp

# 4. Пересоздайте конфигурацию
./warp_ipv6_toggle.sh disable
./warp_ipv6_toggle.sh enable
```

### WARP не запускается

```bash
# Проверьте логи
journalctl -u wg-quick@warp -n 50

# Проверьте конфигурацию
cat /etc/wireguard/warp.conf

# Пересоздайте WARP аккаунт
cd /opt/hiddify-manager/other/warp/wireguard
rm wgcf-account.toml
bash run.sh
```

### После обновления IPv6 перестал работать

```bash
# Обновите репозиторий
cd /opt/hiddify-manager
git pull

# Включите IPv6 заново
./warp_ipv6_toggle.sh enable
```

## Обновление

### Обновление панели

```bash
cd /opt/hiddify-manager
bash common/hiddify_installer.sh release --no-gui
```

### Обновление конфигов из форка

```bash
cd /opt/hiddify-manager
git pull
bash apply_configs.sh
```

### После обновления

Если WARP был включен, переприменить IPv6:

```bash
./warp_ipv6_toggle.sh enable
```

## Интеграция в панель (TODO)

Планируется добавить в настройки панели переключатель "WARP IPv6", который будет вызывать `warp_ipv6_toggle.sh`.

## Совместимость

- ✅ Hiddify Manager v10+
- ✅ Ubuntu 22.04+
- ✅ Debian 11+
- ✅ Любой Linux с IPv6 и WireGuard

## Вклад в проект

Если вы нашли проблему или хотите улучшить исправление:

1. Откройте issue: https://github.com/Xen-neX/Hiddify-Manager/issues
2. Создайте pull request с описанием изменений

## Лицензия

Как и оригинальный Hiddify Manager - см. LICENSE

## Благодарности

- Команде Hiddify за отличную панель
- Сообществу за тестирование и обратную связь

## Ссылки

- Оригинальный репозиторий: https://github.com/hiddify/Hiddify-Manager
- Этот форк: https://github.com/Xen-neX/Hiddify-Manager
- Документация Hiddify: https://github.com/hiddify/Hiddify-Manager/wiki
