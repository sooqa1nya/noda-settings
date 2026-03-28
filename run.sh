#!/bin/bash
# Данные для установки и настройки remnanode на сервере
read -p "IP панели: " panel_ip
echo "Введите содержимое для docker-compose.yml:"
echo "(Для завершения ввода нажмите Ctrl+D)"
echo ""

docker_compose=$(cat)

# Включаем bbr и отключаем ipv6
# 1. net.core.default_qdisc = fq
grep -q '^net\.core\.default_qdisc' /etc/sysctl.conf && sudo sed -i 's/^net\.core\.default_qdisc.*/net.core.default_qdisc = fq/' /etc/sysctl.conf || echo 'net.core.default_qdisc = fq' | sudo tee -a /etc/sysctl.conf
# 2. net.ipv4.tcp_congestion_control = bbr
grep -q '^net\.ipv4\.tcp_congestion_control' /etc/sysctl.conf && sudo sed -i 's/^net\.ipv4\.tcp_congestion_control.*/net.ipv4.tcp_congestion_control = bbr/' /etc/sysctl.conf || echo 'net.ipv4.tcp_congestion_control = bbr' | sudo tee -a /etc/sysctl.conf
# 3. net.ipv6.conf.all.disable_ipv6 = 1
grep -q '^net\.ipv6\.conf\.all\.disable_ipv6' /etc/sysctl.conf && sudo sed -i 's/^net\.ipv6\.conf\.all\.disable_ipv6.*/net.ipv6.conf.all.disable_ipv6 = 1/' /etc/sysctl.conf || echo 'net.ipv6.conf.all.disable_ipv6 = 1' | sudo tee -a /etc/sysctl.conf
# 4. net.ipv6.conf.default.disable_ipv6 = 1
grep -q '^net\.ipv6\.conf\.default\.disable_ipv6' /etc/sysctl.conf && sudo sed -i 's/^net\.ipv6\.conf\.default\.disable_ipv6.*/net.ipv6.conf.default.disable_ipv6 = 1/' /etc/sysctl.conf || echo 'net.ipv6.conf.default.disable_ipv6 = 1' | sudo tee -a /etc/sysctl.conf
# 5. net.ipv6.conf.lo.disable_ipv6 = 1
grep -q '^net\.ipv6\.conf\.lo\.disable_ipv6' /etc/sysctl.conf && sudo sed -i 's/^net\.ipv6\.conf\.lo\.disable_ipv6.*/net.ipv6.conf.lo.disable_ipv6 = 1/' /etc/sysctl.conf || echo 'net.ipv6.conf.lo.disable_ipv6 = 1' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Настройка UFW
sudo ufw allow 22/tcp;
sudo ufw allow 443/tcp;
sudo ufw allow 61000/tcp;
sudo ufw allow from $panel_ip to any port 2222 proto tcp;
sudo ufw deny 2222;
sudo ufw enable;

# Установка Docker и remnawave
sudo curl -fsSL https://get.docker.com | sh
mkdir /opt/remnanode && cd /opt/remnanode
cd /opt/remnanode && echo "$docker_compose" > docker-compose.yml
docker compose up -d && docker compose logs -f -t
