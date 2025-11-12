#!/bin/bash
set -e

echo "🧹 Шаг 0: Очистка системы и завершение процессов..."
sudo pkill -f "x11vnc|chromium|start_server|upgrade" && echo "✅ Процессы закрыты"

sudo rm -rf ~/.cache/* || true
sudo rm -rf /tmp/* || true
sudo rm -rf /var/tmp/* || true

sync && echo 3 | sudo tee /proc/sys/vm/drop_caches
echo "🧼 Очистка завершена."

echo "📦 Шаг 0.5: Настройка swap-файла 4 GiB..."
sudo swapoff /swap/swapfile || true
sudo rm -f /swap/swapfile

sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

echo "📊 Проверка памяти и swap:"
swapon --show
free -h

echo "🔧 Шаг 1: Установка Docker..."
sudo apt update && sudo apt install -y docker.io

echo "🚀 Шаг 2: Запуск демона Docker на 16 секунд..."
# запустить докер без вывода, в фоне
sudo dockerd > /dev/null 2>&1 &
DOCKER_PID=$!
sleep 16

echo "⛔ Остановка демона Docker..."
# убить все процессы dockerd/containerd
sudo pkill -f dockerd || true
sudo pkill -f containerd || true
wait $DOCKER_PID 2>/dev/null || true
echo "✅ Демон Docker остановлен."

echo "📦 Шаг 3: Запуск контейнера Arch Linux и установка пакетов..."
docker run --network=host -it archlinux bash -c "
  echo '🔄 Обновление системы...'
  pacman -Syu --noconfirm

  echo '📥 Установка необходимых пакетов...'
  pacman -S --noconfirm wget curl gmp boost nano base-devel gcc glibc

  echo '⬇️ Загрузка rieMiner...'
  wget https://riecoin.xyz/rieMiner/Download/Deb64AVX2 -O rieminer.deb

  echo '📦 Подготовка rieMiner...'
  mv rieminer.deb rieminer2
  chmod +x rieminer2

  echo '📝 Создание конфигурации rieMiner.conf...'
  echo -e 'Mode = Pool\nHost = ric.suprnova.cc\nPort = 5000\nUsername = lomalo.lomalo\nPassword = pass\nThreads = 4' > rieMiner.conf

  echo '✅ Установка завершена. Запуск майнинга...'
  ./rieminer2
"

