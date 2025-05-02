#!/bin/bash

# Кольори для виводу
GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Лого
echo -e '\e[0;32m'
curl -s https://raw.githubusercontent.com/Crypto-Familly/crypto-familly-logo/refs/heads/main/logo.sh | bash
echo -e '\e[0m'

# Повідомлення
success_message() {
    echo -e "${GREEN}[✔] $1${NC}"
}
info_message() {
    echo -e "${CYAN}[-] $1...${NC}"
}
error_message() {
    echo -e "${RED}[✘] $1${NC}"
}

# Встановлення Docker
install_docker() {
    if ! command -v docker &>/dev/null; then
        info_message "Docker не знайдено, встановлюю..."
        sudo apt update && sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
          $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt update
        sudo apt install -y docker-ce docker-ce-cli containerd.io
        sudo systemctl start docker
        sudo systemctl enable docker
        success_message "Docker встановлено."
    else
        success_message "Docker вже встановлено."
    fi
}

# Ініціалізація ноди
init_node() {
    mkdir -p ~/privasea/config && cd ~/privasea
    info_message "Створення нового keystore..."
    sudo docker run --rm -it -v "$HOME/privasea/config:/app/config" privasea/acceleration-node-beta:latest ./node-calc new_keystore
    cd ~/privasea/config
    KEYSTORE_FILE=$(ls UTC*)
    if [ -z "$KEYSTORE_FILE" ]; then
        error_message "Keystore файл не знайдено."
        exit 1
    fi
    mv "$KEYSTORE_FILE" wallet_keystore
    success_message "Keystore файл збережено як wallet_keystore."
}

# Запуск ноди
start_node() {
    read -s -p "Введіть пароль для keystore: " KEYSTORE_PASSWORD
    echo
    cd ~/privasea
    sudo docker run -d -v "$HOME/privasea/config:/app/config" -e KEYSTORE_PASSWORD="$KEYSTORE_PASSWORD" privasea/acceleration-node-beta:latest
    success_message "Нода запущена."
}

# Перегляд логів
view_logs() {
    CONTAINER_ID=$(sudo docker ps -q --filter ancestor=privasea/acceleration-node-beta:latest)
    if [ -z "$CONTAINER_ID" ]; then
        error_message "Нода не запущена або контейнер не знайдено."
    else
        echo -e "${YELLOW}Вивід логів (натисніть Ctrl+C для виходу):${NC}"
        sudo docker logs -f "$CONTAINER_ID"
    fi
}

# Меню
main_menu() {
    clear
    echo -e "${CYAN}========= Privasea Node Меню =========${NC}"
    echo "1. Встановити Docker"
    echo "2. Ініціалізувати ноду (створити keystore)"
    echo "3. Запустити ноду"
    echo "4. Переглянути логи ноди"
    echo "5. Вийти"
    echo -n "Виберіть опцію [1-5]: "
    read CHOICE

    case $CHOICE in
        1) install_docker ;;
        2) init_node ;;
        3) start_node ;;
        4) view_logs ;;
        5) exit 0 ;;
        *) error_message "Невірна опція. Спробуйте ще раз." ;;
    esac

    echo -e "\nНатисніть Enter для повернення до меню..."
    read
    main_menu
}

main_menu
