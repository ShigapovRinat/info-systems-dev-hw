
set -e  # Остановка при ошибке

# --- Конфигурация ---
YC_FOLDER_ID="b1gaie1vs6mtv67qqjrs"
YC_ZONE="ru-central1-b"
YC_SUBNET_NAME="jmix-subnet"
YC_VM_NAME="jmix-vm"
SSH_KEY_PATH="$HOME/.ssh/jmix-key"
DOCKER_IMAGE="jmix/jmix-bookstore"
VM_USER="ipiris"

# Проверка наличия Yandex Cloud CLI
if ! command -v yc &> /dev/null; then
    echo "Ошибка: Yandex Cloud CLI (yc) не установлен."
    exit 1
fi

# Проверка авторизации в Yandex Cloud
if ! yc config list &> /dev/null; then
    echo "Ошибка: Необходимо авторизоваться в Yandex Cloud (yc init)."
    exit 1
fi

# --- Создание сети и подсети ---
echo "Создаём сеть и подсеть..."
yc vpc network create --name jmix-network
yc vpc subnet create \
    --name "$YC_SUBNET_NAME" \
    --zone "$YC_ZONE" \
    --range 192.168.1.0/24 \
    --network-name jmix-network

# --- Генерация SSH-ключей ---
if [ ! -f "$SSH_KEY_PATH" ]; then
    echo "Генерируем SSH-ключи..."
    ssh-keygen -t rsa -b 2048 -f "$SSH_KEY_PATH" -N ""
fi
SSH_PUBLIC_KEY=$(cat "$SSH_KEY_PATH.pub")

# --- Создание виртуальной машины ---
echo "Создаём виртуальную машину..."
VM_ID=$(yc compute instance create \
    --name "$YC_VM_NAME" \
    --zone "$YC_ZONE" \
    --network-interface subnet-name="$YC_SUBNET_NAME",nat-ip-version=ipv4 \
    --cores 2 \
    --memory 4G \
    --ssh-key "$SSH_KEY_PATH" \
    --format json | jq -r '.id')

# Получение внешнего IP-адреса
VM_IP=$(yc compute instance get --id "$VM_ID" --format json | jq -r '.network_interfaces[0].primary_v4_address.one_to_one_nat.address')

# --- Настройка ВМ и установка Docker ---
echo "Устанавливаем Docker и запускаем контейнер..."
ssh -o StrictHostKeyChecking=no -i "$SSH_KEY_PATH" "$VM_USER@$VM_IP" <<EOF
    set -e
    sudo apt update
    sudo apt install -y docker.io
    sudo systemctl enable --now docker
    sudo docker run -d -p 80:8080 --name bookstore "$DOCKER_IMAGE"
EOF

# --- Вывод данных для подключения ---
echo "Виртуальная машина успешно создана!"
echo "Подключение по SSH: ssh -i $SSH_KEY_PATH $VM_USER@$VM_IP"
echo "Веб-приложение доступно по адресу: http://$VM_IP"
