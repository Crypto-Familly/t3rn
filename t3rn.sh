#!/bin/bash

# колір тексту
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # Немає кольору (скидання кольору)

# Перевірка наявності curl та встановлення, якщо не встановлено 
if ! command -v curl &> /dev/null; then
    sudo apt update
    sudo apt install curl -y
fi
sleep 1

# Відображаємо логотип
curl -s https://raw.githubusercontent.com/Crypto-Familly/crypto-familly-logo/refs/heads/main/logo.sh | bash

# Перевірка наявності bc та встановлення, якщо не встановлено
if ! command -v bc &> /dev/null; then
    sudo apt update
    sudo apt install bc -y
fi
sleep 1

# Перевірка версії Ubuntu
UBUNTU_VERSION=$(lsb_release -rs)
REQUIRED_VERSION=22.04

if (( $(echo "$UBUNTU_VERSION < $REQUIRED_VERSION" | bc -l) )); then
    echo -e "${RED}Для этой ноды нужна минимальная версия Ubuntu 22.04${NC}"
    exit 1
fi

# Меню
echo -e "${YELLOW}Виберіть дію:${NC}"
echo -e "${CYAN}1) Встановлення ноди${NC}"
echo -e "${CYAN}2) Оновлення ноди${NC}"
echo -e "${CYAN}3) Перевірка логів${NC}"
echo -e "${CYAN}4) Рестарт ноди${NC}"
echo -e "${CYAN}5) Видалення ноди${NC}"

echo -e "${YELLOW}Введіть номер :${NC} "
read choice

case $choice in
    1)
        echo -e "${BLUE}Встановлюємо ноду t3rn...${NC}"

        # Оновлення та встановлення залежностей
        sudo apt update
        sudo apt upgrade -y

        # Завантажуємо бінарник
        #LATEST_VERSION=$(curl -s https://api.github.com/repos/t3rn/executor-release/releases/latest | grep 'tag_name' | cut -d\" -f4)
        EXECUTOR_URL="https://github.com/t3rn/executor-release/releases/download/v0.69.0/executor-linux-v0.69.0.tar.gz"
        curl -L -o executor-linux-v0.69.0.tar.gz $EXECUTOR_URL

        # Вилучаємо
        tar -xzvf executor-linux-v0.69.0.tar.gz
        rm -rf executor-linux-v0.69.0.tar.gz

        # Визначаємо користувача та домашню директорію
        USERNAME=$(whoami)
        HOME_DIR=$(eval echo ~$USERNAME)

        # Створюємо .t3rn та записуємо приватний ключ
        CONFIG_FILE="$HOME_DIR/executor/executor/bin/.t3rn"
        echo "ENVIRONMENT=testnet" >> $CONFIG_FILE
        echo "EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API=false" > $CONFIG_FILE
        echo "EXECUTOR_PROCESS_ORDERS_API_ENABLED=false" > $CONFIG_FILE
        echo "EXECUTOR_PROCESS_BIDS_BATCH=true" > $CONFIG_FILE
        echo "EXECUTOR_ENABLE_BATCH_BIDDING=true" > $CONFIG_FILE
        echo "LOG_LEVEL=debug" >> $CONFIG_FILE
        echo "LOG_PRETTY=false" >> $CONFIG_FILE
        echo "EXECUTOR_PROCESS_BIDS_ENABLED=true" >> $CONFIG_FILE
        echo "EXECUTOR_PROCESS_ORDERS=true" >> $CONFIG_FILE
        echo "EXECUTOR_PROCESS_CLAIMS=true" >> $CONFIG_FILE
        echo "PRIVATE_KEY_LOCAL=" >> $CONFIG_FILE
        echo "EXECUTOR_MAX_L3_GAS_PRICE=1000" >> $CONFIG_FILE
        echo "ENABLED_NETWORKS='arbitrum-sepolia,base-sepolia,optimism-sepolia,l2rn,unichain-sepolia'" >> $CONFIG_FILE
        echo "NETWORKS_DISABLED='blast-sepolia,monad-testnet,arbitrum,base,optimism,sei-testnet'" >> $CONFIG_FILE
        cat <<EOF >> $CONFIG_FILE
RPC_ENDPOINTS='{
    "l2rn": ["https://t3rn-b2n.blockpi.network/v1/rpc/public", "https://b2n.rpc.caldera.xyz/http"],
    "arbt": ["https://arbitrum-sepolia-rpc.publicnode.com"],
    "bast": ["https://sepolia.base.org"],
    "blst": ["https://blast-sepolia.blockpi.network/v1/rpc/public"],
    "mont": ["https://testnet-rpc.monad.xyz"],
    "opst": ["https://optimism-sepolia-rpc.publicnode.com"],
    "unit": ["https://unichain-sepolia.blockpi.network/v1/rpc/public"]
}'
EOF
        if ! grep -q "ENVIRONMENT=testnet" "$HOME/executor/executor/bin/.t3rn"; then
          echo "ENVIRONMENT=testnet" >> "$HOME/executor/executor/bin/.t3rn"
        fi

        echo -e "${YELLOW}Введіть свій приватний ключ:${NC}"
        read PRIVATE_KEY
        sed -i "s|PRIVATE_KEY_LOCAL=|PRIVATE_KEY_LOCAL=$PRIVATE_KEY|" $CONFIG_FILE

        # Створюємо сервісник
        sudo bash -c "cat <<EOT > /etc/systemd/system/t3rn.service
[Unit]
Description=t3rn Service
After=network.target

[Service]
EnvironmentFile=$HOME_DIR/executor/executor/bin/.t3rn
ExecStart=$HOME_DIR/executor/executor/bin/executor
WorkingDirectory=$HOME_DIR/executor/executor/bin/
Restart=on-failure
User=$USERNAME

[Install]
WantedBy=multi-user.target
EOT"

        # Запуск сервиса
        sudo systemctl daemon-reload
        sudo systemctl restart systemd-journald
        sleep 1
        sudo systemctl enable t3rn
        sudo systemctl start t3rn
        sleep 2

        # Заключний висновок
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}Команда для перевірки логів:${NC}"
        echo "sudo journalctl -u t3rn -f"
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${GREEN}Сrypto Familly${NC}"
        echo -e "${CYAN}Наш Telegram https://t.me/Crypto_Familly_Activity${NC}"
        sleep 2

        # Перевірка логів
        sudo journalctl -u t3rn -f
        ;;
    2)
        echo -e "${BLUE}Оновлення ноди t3rn...${NC}"

        # Зупинка сервісу
        sudo systemctl stop t3rn

        # Видаляємо папку executor
        cd
        rm -rf executor/

        # Завантажуємо новий бінарник
        #LATEST_VERSION=$(curl -s https://api.github.com/repos/t3rn/executor-release/releases/latest | grep 'tag_name' | cut -d\" -f4)
        EXECUTOR_URL="https://github.com/t3rn/executor-release/releases/download/v0.69.0/executor-linux-v0.69.0.tar.gz"
        curl -L -o executor-linux-v0.69.0.tar.gz $EXECUTOR_URL
        tar -xzvf executor-linux-v0.69.0.tar.gz
        rm -rf executor-linux-v0.69.0.tar.gz

        # Визначаємо користувача та домашню директорію
        USERNAME=$(whoami)
        HOME_DIR=$(eval echo ~$USERNAME)
        
        # Створюємо .t3rn та записуємо приватний ключ
        CONFIG_FILE="$HOME_DIR/executor/executor/bin/.t3rn"
        echo "ENVIRONMENT=testnet" >> $CONFIG_FILE
        echo "EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API=false" > $CONFIG_FILE
        echo "EXECUTOR_PROCESS_ORDERS_API_ENABLED=false" > $CONFIG_FILE
        echo "EXECUTOR_PROCESS_BIDS_BATCH=true" > $CONFIG_FILE
        echo "EXECUTOR_ENABLE_BATCH_BIDDING=true" > $CONFIG_FILE
        echo "LOG_LEVEL=debug" >> $CONFIG_FILE
        echo "LOG_PRETTY=false" >> $CONFIG_FILE
        echo "EXECUTOR_PROCESS_BIDS_ENABLED=true" >> $CONFIG_FILE
        echo "EXECUTOR_PROCESS_ORDERS=true" >> $CONFIG_FILE
        echo "EXECUTOR_PROCESS_CLAIMS=true" >> $CONFIG_FILE
        echo "PRIVATE_KEY_LOCAL=" >> $CONFIG_FILE
        echo "EXECUTOR_MAX_L3_GAS_PRICE=1000" >> $CONFIG_FILE
        echo "ENABLED_NETWORKS='arbitrum-sepolia,base-sepolia,optimism-sepolia,unichain-sepolia'" >> $CONFIG_FILE
        echo "NETWORKS_DISABLED='blast-sepolia,monad-testnet,arbitrum,base,optimism,sei-testnet'" >> $CONFIG_FILE
        cat <<EOF >> $CONFIG_FILE
RPC_ENDPOINTS='{
    "l2rn": ["https://t3rn-b2n.blockpi.network/v1/rpc/public"],
    "arbt": ["https://arbitrum-sepolia-rpc.publicnode.com"],
    "bast": ["https://sepolia.base.org"],
    "blst": ["https://blast-sepolia.blockpi.network/v1/rpc/public"],
    "mont": ["https://testnet-rpc.monad.xyz"],
    "opst": ["https://optimism-sepolia-rpc.publicnode.com"],
    "unit": ["https://unichain-sepolia.blockpi.network/v1/rpc/public"]
}'
EOF

        if ! grep -q "ENVIRONMENT=testnet" "$HOME/executor/executor/bin/.t3rn"; then
          echo "ENVIRONMENT=testnet" >> "$HOME/executor/executor/bin/.t3rn"
        fi

        echo -e "${YELLOW}Введіть свій приватний ключ:${NC}"
        read PRIVATE_KEY
        sed -i "s|PRIVATE_KEY_LOCAL=|PRIVATE_KEY_LOCAL=$PRIVATE_KEY|" $CONFIG_FILE

        # Релоад деймонов
        sudo systemctl daemon-reload
        sudo systemctl restart systemd-journald
        sudo systemctl start t3rn
        sleep 2

        # Заключительный вывод
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}Команда для перевірки логів:${NC}"
        echo "sudo journalctl -u t3rn -f"
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${GREEN}Сrypto Familly${NC}"
        echo -e "${CYAN}Наш Telegram https://t.me/Crypto_Familly_Activity${NC}"
        sleep 2

        # Проверка логов
        sudo journalctl -u t3rn -f
        ;;
    3)
        # Проверка логов
        sudo journalctl -u t3rn -f
        ;;
    4)
        # Рестарт ноды
        sudo systemctl restart t3rn
        sudo journalctl -u t3rn -f
        ;;
    5)
        echo -e "${BLUE}Видалення ноди t3rn...${NC}"

        # Остановка и удаление сервиса
        sudo systemctl stop t3rn
        sudo systemctl disable t3rn
        sudo rm /etc/systemd/system/t3rn.service
        sudo systemctl daemon-reload
        sleep 2

        # Удаление папки executor
        rm -rf $HOME/executor

        echo -e "${GREEN}Нода t3rn успішно видалено!${NC}"

        # Заключительный вывод
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${GREEN}Сrypto Familly${NC}"
        echo -e "${CYAN}Наш Telegram https://t.me/Crypto_Familly_Activity${NC}"
        sleep 1
        ;;
    *)
        echo -e "${RED}Неправильний вибір. Будь ласка, введіть номер від 1 до 5.${NC}"
        ;;
esac
