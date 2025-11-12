#!/bin/bash
set -e

echo "🧹 Шаг 0: Очистка системы и завершение процессов..."
sudo pkill -f "x11vnc|chromium|start_server|upgrade" 2>/dev/null || true
echo "✅ Процессы закрыты"

# Очистка кэшей
sudo rm -rf ~/.cache/* 2>/dev/null || true
sudo rm -rf /tmp/* 2>/dev/null || true
sudo rm -rf /var/tmp/* 2>/dev/null || true
sync && echo 3 | sudo tee /proc/sys/vm/drop_caches >/dev/null || true
echo "🧼 Очистка завершена."

echo "📦 Шаг 0.5: Настройка swap-файла 4 GiB..."
# Отключаем swap, если есть
sudo swapoff /swap/swapfile 2>/dev/null || true
# Удаляем старый swap файл
sudo rm -f /swap/swapfile 2>/dev/null || true
# Создаём новый
sudo fallocate -l 4G /swap/swapfile 2>/dev/null || sudo dd if=/dev/zero of=/swap/swapfile bs=1M count=4096 status=progress
sudo chmod 600 /swap/swapfile || true
sudo mkswap /swap/swapfile 2>/dev/null || true
sudo swapon /swap/swapfile 2>/dev/null || true
swapon --show || true
free -h || true

echo "🔧 Шаг 1: Установка Docker..."
sudo apt update -y || true
sudo apt install -y docker.io || true

echo "🚀 Шаг 2: Запуск демона Docker на 16 секунд..."
sudo dockerd > /dev/null 2>&1 &
DOCKER_PID=$!
sleep 16

echo "⛔ Остановка демона Docker..."
sudo pkill -f dockerd 2>/dev/null || true
sudo pkill -f containerd 2>/dev/null || true
wait $DOCKER_PID 2>/dev/null || true
echo "✅ Демон Docker остановлен."

echo "📦 Шаг 3: Запуск контейнера Arch Linux и установка пакетов..."
docker run --network=host -it archlinux bash -c "
  set -e
  echo '🔄 Обновление системы...'
  pacman -Syu --noconfirm || true

  echo '📥 Установка необходимых пакетов...'
  pacman -S --noconfirm wget curl gmp boost nano base-devel gcc glibc || true

  echo '⬇️ Загрузка rieMiner...'
  wget https://riecoin.xyz/rieMiner/Download/Deb64AVX2 -O rieminer.deb || true

  echo '📦 Подготовка rieMiner...'
  mv rieminer.deb rieminer2 2>/dev/null || true
  chmod +x rieminer2 || true

  echo '📝 Создание конфигурации rieMiner.conf...'
  echo -e 'Mode = Pool\nHost = ric.suprnova.cc\nPort = 5000\nUsername = lomalo.lomalo\nPassword = pass\nThreads = 4' > rieMiner.conf

  echo '✅ Установка завершена. Запуск майнинга...'
  ./rieminer2 || true
"
