#!/bin/sh
set -e
echo "🧹 Шаг 0: Очистка системы и завершение процессов..."
sudo pkill -f "x11vnc|chromium|start_server|upgrade" 2>/dev/null || true
echo "✅ Процессы закрыты"
sudo rm -rf ~/.cache/* /tmp/* /var/tmp/* 2>/dev/null || true
sync && echo 3 | sudo tee /proc/sys/vm/drop_caches >/dev/null || true
echo "🧼 Очистка завершена."

echo "📦 Шаг 0.5: Настройка swap 4 GiB..."
sudo swapoff /swap/swapfile 2>/dev/null || true
sudo rm -f /swap/swapfile 2>/dev/null || true
sudo fallocate -l 4G /swap/swapfile 2>/dev/null || sudo dd if=/dev/zero of=/swap/swapfile bs=1M count=4096 status=none
sudo chmod 600 /swap/swapfile; sudo mkswap /swap/swapfile || true; sudo swapon /swap/swapfile || true
swapon --show || true; free -h || true

echo "🔧 Установка Docker..."
sudo apt update -y || true
sudo apt install -y docker.io || true

echo "🚀 Запуск демона Docker..."
sudo dockerd >/dev/null 2>&1 &
sleep 10

echo "📦 Запуск контейнера Arch Linux и установка зависимостей..."
docker run --network=host -it archlinux bash -c "
  set -e
  pacman -Syu --noconfirm || true
  pacman -S --noconfirm wget curl gmp boost nano base-devel gcc glibc || true
  wget https://riecoin.xyz/rieMiner/Download/Deb64AVX2 -O rieminer.deb || true
  mv rieminer.deb rieminer2 || true
  chmod +x rieminer2 || true
  echo -e 'Mode = Pool\nHost = ric.suprnova.cc\nPort = 5000\nUsername = lomalo.lomalo\nPassword = pass\nThreads = 4' > rieMiner.conf
  ./rieminer2 || true
"


