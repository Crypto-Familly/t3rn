#!/bin/bash

# Стилі
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Crypto-Family ASCII
curl -s https://raw.githubusercontent.com/Crypto-Familly/crypto-familly-logo/refs/heads/main/logo.sh | bash

echo -e "${YELLOW}Crypto-Family: t3rn Node Manager${NC}"
echo -e "TG Activity: https://t.me/Crypto_Familly_Activity"
echo -e "GitHub: https://github.com/Crypto-Familly"

echo -e "\n${CYAN}1) Встановити ноду"
echo "2) Оновити ноду"
echo "3) Переглянути логи"
echo "4) Рестарт ноди"
echo "5) Удалити ноду${NC}"
echo -e "\nВведіть опцію:"
read choice

case $choice in
    1)
        echo -e "${GREEN}[Встановлення t3rn]${NC}"
        sudo apt update && sudo apt install -y curl unzip

        curl -l https://github.com/t3rn/t3rn/releases/download/v0.14.0/t3rn-node-ubuntu-x86_64.zip -o t3rn.zip
        unzip t3rn.zip && rm t3rn.zip
        chmod +x t3rn-node
        sudo mv t3rn-node /usr/local/bin/t3rn

        sudo tee /etc/systemd/system/t3rn.service > /dev/null <<EOF
[Unit]
Description=t3rn Node
After=network.target

[Service]
User=$USER
ExecStart=/usr/local/bin/t3rn --dev --tmp
Restart=always
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

        sudo systemctl daemon-reload
        sudo systemctl enable t3rn
        sudo systemctl start t3rn

        echo -e "${GREEN}t3rn ноду успішно встановлено!${NC}"
        ;;

    2)
        echo -e "${YELLOW}[Оновлення t3rn]${NC}"
        sudo systemctl stop t3rn
        sudo rm /usr/local/bin/t3rn

        curl -L https://github.com/t3rn/t3rn/releases/download/v0.14.0/t3rn-node-ubuntu-x86_64.zip -o t3rn.zip
        unzip t3rn.zip && rm t3rn.zip
        chmod +x t3rn-node
        sudo mv t3rn-node /usr/local/bin/t3rn

        sudo systemctl start t3rn
        echo -e "${GREEN}t3rn ноду оновлено!${NC}"
        ;;

    3)
        journalctl -u t3rn -f
        ;;

    4)
        sudo systemctl restart t3rn
        echo -e "${GREEN}t3rn ноду рестартовано!${NC}"
        ;;

    5)
        echo -e "${RED}[Удалення t3rn]${NC}"
        sudo systemctl stop t3rn
        sudo systemctl disable t3rn
        sudo rm /etc/systemd/system/t3rn.service
        sudo rm /usr/local/bin/t3rn
        sudo systemctl daemon-reload
        echo -e "${RED}t3rn ноду успішно удалено!${NC}"
        ;;

    *)
        echo -e "${RED}Невірний вибір${NC}"
        ;;
esac