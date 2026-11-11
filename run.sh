#!/bin/bash

# Остановка скрипта в случае критической ошибки
set -e

# Данные для установки и настройки remnanode на сервере
read -p "IP панели: " panel_ip
echo "Введите содержимое для docker-compose.yml:"
echo "(Для завершения ввода нажмите Ctrl+D)"
echo ""

docker_compose=$(cat)

# Полное обновление системы и установка необходимых пакетов (ufw и curl)
apt update
apt full-upgrade -y
apt install ufw curl -y

# Включаем BBR и отключаем IPv6
configs=(
    "net.core.default_qdisc = fq"
    "net.ipv4.tcp_congestion_control = bbr"
    "net.ipv6.conf.all.disable_ipv6 = 1"
    "net.ipv6.conf.default.disable_ipv6 = 1"
    "net.ipv6.conf.lo.disable_ipv6 = 1"
)

for conf in "${configs[@]}"; do
    key=$(echo "$conf" | cut -d' ' -f1)
    if grep -q "^$key" /etc/sysctl.conf; then
        sed -i "s/^$key.*/$conf/" /etc/sysctl.conf
    else
        echo "$conf" >> /etc/sysctl.conf
    fi
done

# Применяем сетевые настройки
sysctl -p

# Настройка UFW
ufw allow 22/tcp
ufw allow 443/tcp
ufw allow from "$panel_ip" to any port 2222 proto tcp
ufw deny 2222
# Включение UFW без запроса подтверждения (y/n)
ufw --force enable

# Установка Docker
curl -fsSL https://get.docker.com | sh

# Настройка и запуск remnanode
mkdir -p /opt/remnanode
cd /opt/remnanode
echo "$docker_compose" > docker-compose.yml

# Запуск контейнеров и вывод логов
docker compose up -d
docker compose logs -f -t
