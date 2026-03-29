# Установка форка Hiddify Manager с исправлением IPv6

## Рекомендуемый способ: Автоматическая установка

Используйте специальный скрипт для установки форка:

```bash
# Скачайте и запустите установочный скрипт
curl -o install_fork.sh https://raw.githubusercontent.com/Xen-neX/Hiddify-Manager/main/install_fork.sh
chmod +x install_fork.sh
./install_fork.sh
```

Скрипт автоматически:
- Клонирует/обновляет форк
- Создаст бэкап существующей установки (если есть)
- Установит Hiddify Manager с конфигами из форка
- Применит IPv6 WARP fix

## Вариант 1: Чистая установка (ручной способ)

Если у вас еще не установлен Hiddify Manager:

```bash
# 1. Клонируйте ваш форк
cd /opt
git clone https://github.com/Xen-neX/Hiddify-Manager.git hiddify-manager
cd hiddify-manager

# 2. Запустите стандартный установщик Hiddify
bash common/hiddify_installer.sh release --no-gui

# 3. После установки примените IPv6 fix
chmod +x fix_warp_ipv6.sh
./fix_warp_ipv6.sh
```

## Вариант 2: Обновление существующей установки (безопасно)

Если Hiddify Manager уже установлен из оригинального репозитория:

```bash
cd /opt/hiddify-manager

# 1. Сделайте бэкап текущей конфигурации
tar -czf ~/hiddify-backup-$(date +%Y%m%d_%H%M%S).tar.gz \
    hiddify-panel/hiddifypanel.db \
    ssl/ \
    other/warp/wireguard/wgcf-account.toml 2>/dev/null || true

echo "Backup created in ~/hiddify-backup-*.tar.gz"

# 2. Добавьте ваш форк как remote
git remote add fork https://github.com/Xen-neX/Hiddify-Manager.git

# 3. Получите изменения из форка
git fetch fork

# 4. Примените изменения из форка (сохраняя локальные файлы)
git pull fork main --no-rebase

# Если возникнут конфликты, разрешите их:
# git status  # посмотрите конфликтующие файлы
# git checkout --theirs <file>  # взять версию из форка
# git add <file>
# git commit

# 5. Примените конфигурации
bash apply_configs.sh

# 6. Примените IPv6 fix
chmod +x fix_warp_ipv6.sh
./fix_warp_ipv6.sh
```

## Вариант 3: Только патч IPv6 (минимальное вмешательство)

Если вы хотите применить только исправление IPv6 без переключения на форк:

```bash
cd /opt/hiddify-manager

# 1. Скачайте исправленные файлы
curl -o other/warp/wireguard/run.sh.j2 \
  https://raw.githubusercontent.com/Xen-neX/Hiddify-Manager/main/other/warp/wireguard/run.sh.j2

curl -o other/warp/singbox/run.sh \
  https://raw.githubusercontent.com/Xen-neX/Hiddify-Manager/main/other/warp/singbox/run.sh

curl -o fix_warp_ipv6.sh \
  https://raw.githubusercontent.com/Xen-neX/Hiddify-Manager/main/fix_warp_ipv6.sh

# 2. Примените fix
chmod +x fix_warp_ipv6.sh
./fix_warp_ipv6.sh
```

## Вариант 4: Полная замена на форк (для опытных пользователей)

```bash
cd /opt/hiddify-manager

# 1. Бэкап (обязательно!)
tar -czf ~/hiddify-backup-$(date +%Y%m%d_%H%M%S).tar.gz \
    hiddify-panel/hiddifypanel.db \
    ssl/ \
    other/warp/wireguard/wgcf-account.toml 2>/dev/null || true

# 2. Измените origin на ваш форк
git remote set-url origin https://github.com/Xen-neX/Hiddify-Manager.git

# 3. Получите изменения
git fetch origin

# 4. Сбросьте на версию форка (ВНИМАНИЕ: удалит локальные изменения!)
git reset --hard origin/main

# 5. Примените конфигурации
bash apply_configs.sh

# 6. Примените IPv6 fix
chmod +x fix_warp_ipv6.sh
./fix_warp_ipv6.sh
```

## Проверка после установки

После любого из вариантов проверьте:

```bash
# 1. Проверьте, что используется ваш форк
cd /opt/hiddify-manager
git remote -v

# 2. Проверьте версию
cat VERSION

# 3. Проверьте, что IPv6 fix применен
cat /etc/wireguard/warp.conf | grep "oif warp"

# 4. Проверьте IPv6 через WARP
curl -6 --interface warp https://v6.ident.me/

# 5. Проверьте статус служб
systemctl status hiddify-panel
systemctl status wg-quick@warp
```

## Обновление форка в будущем

Когда вы внесете новые изменения в форк:

```bash
cd /opt/hiddify-manager

# Получите последние изменения
git pull origin main
# или если использовали remote "fork":
git pull fork main

# Примените конфигурации
bash apply_configs.sh

# Перезапустите службы если нужно
systemctl restart hiddify-panel
```

## Восстановление из бэкапа (если что-то пошло не так)

```bash
# Остановите службы
systemctl stop hiddify-panel wg-quick@warp

# Восстановите из бэкапа
cd /opt
rm -rf hiddify-manager
tar -xzf ~/hiddify-backup-YYYYMMDD_HHMMSS.tar.gz

# Запустите службы
systemctl start hiddify-panel wg-quick@warp
```

## Рекомендации

- **Для продакшн серверов**: используйте Вариант 2 (обновление с бэкапом)
- **Для новых серверов**: используйте Вариант 1 (чистая установка)
- **Для быстрого теста**: используйте Вариант 3 (только патч)
- **Для разработки**: используйте Вариант 4 (полная замена)

## Важные замечания

1. **Всегда делайте бэкап** перед любыми изменениями
2. **Проверяйте работу** после обновления
3. **Сохраните WARP аккаунт**: файл `wgcf-account.toml` содержит ваш WARP+ аккаунт
4. **База данных**: файл `hiddifypanel.db` содержит всех пользователей и настройки
5. **SSL сертификаты**: папка `ssl/` содержит ваши сертификаты

## Поддержка

Если возникли проблемы:
- Проверьте логи: `journalctl -u hiddify-panel -f`
- Проверьте WARP: `journalctl -u wg-quick@warp -f`
- Откройте issue в репозитории: https://github.com/Xen-neX/Hiddify-Manager/issues
