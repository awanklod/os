#!/bin/bash

# --- Pemeriksaan Awal ---
# Memastikan file konfigurasi yang dibutuhkan ada sebelum melanjutkan
for file in /etc/xray/dns /etc/slowdns/server.pub /etc/xray/domain; do
    if [ ! -f "$file" ]; then
        echo "Error: File konfigurasi $file tidak ditemukan. Instalasi dibatalkan."
        exit 1
    fi
done

NS=$(cat /etc/xray/dns)
PUB=$(cat /etc/slowdns/server.pub)
domain=$(cat /etc/xray/domain)

# --- Variabel Warna ---
grenbo="\e[92;1m"
NC='\e[0m'

# --- Persiapan dan Instalasi Dependensi ---
echo "Menghentikan dan menonaktifkan service lama (jika ada)..."
systemctl stop kyt.service > /dev/null 2>&1
systemctl disable kyt.service > /dev/null 2>&1

echo "Membersihkan instalasi lama..."
# Lokasi instalasi baru yang lebih bersih
INSTALL_DIR="/opt/kytbot"
rm -rf "$INSTALL_DIR"
rm -f /etc/systemd/system/kyt.service

# Membersihkan file usang dari /usr/bin jika ada
rm -f /usr/bin/kyt /usr/bin/bot

echo "Memperbarui sistem dan menginstal dependensi..."
apt-get update
apt-get install -y wget curl neofetch python3 python3-pip git unzip figlet lolcat

# --- Instalasi Aplikasi Bot ---
echo "Mengunduh dan menginstal aplikasi bot..."
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR" || exit

# Mengunduh dan mengatur tool tambahan
wget -q https://raw.githubusercontent.com/awanklod/os/main/bot/bot.zip
unzip -o bot.zip
# Hanya pindahkan file yang diperlukan dan berikan izin eksekusi
mv bot/bot /usr/local/bin/
chmod +x /usr/local/bin/bot
rm -rf bot bot.zip

# Mengunduh dan mengatur aplikasi utama Kyt
wget -q https://raw.githubusercontent.com/awanklod/os/main/bot/kyt.zip
unzip -o kyt.zip
rm -rf kyt.zip

# Menginstal dependensi Python
if [ -f "$INSTALL_DIR/kyt/requirements.txt" ]; then
    pip3 install -r "$INSTALL_DIR/kyt/requirements.txt"
fi

# --- Konfigurasi Bot ---
clear
figlet Xwan Vpn | lolcat
echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e " \e[1;97;101m           ADD BOT PANEL           \e[0m"
echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "${grenbo}Tutorial Membuat Bot dan Mendapatkan ID Telegram${NC}"
echo -e "${grenbo}[*] Buat Bot & Token Bot di: @BotFather${NC}"
echo -e "${grenbo}[*] Dapatkan Info ID Telegram di: @MissRose_bot (gunakan perintah /info)${NC}"
echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
read -e -p "[*] Masukkan Token Bot Anda: " bottoken
read -e -p "[*] Masukkan ID Telegram Anda: " admin

# Menulis konfigurasi ke file var.txt
VAR_FILE="$INSTALL_DIR/kyt/var.txt"
echo "Menulis konfigurasi ke $VAR_FILE"
rm -f "$VAR_FILE" # Hapus file lama untuk menghindari duplikasi
echo -e "BOT_TOKEN=\"$bottoken\"" >> "$VAR_FILE"
echo -e "ADMIN=\"$admin\"" >> "$VAR_FILE"
echo -e "DOMAIN=\"$domain\"" >> "$VAR_FILE"
echo -e "PUB=\"$PUB\"" >> "$VAR_FILE"
echo -e "HOST=\"$NS\"" >> "$VAR_FILE"

# Membuat direktori dan database bot
mkdir -p /etc/bot
echo -e "#bot# $bottoken $admin" > /etc/bot/.bot.db
clear

# --- Pembuatan Service Systemd ---
echo "Membuat service systemd untuk kyt..."
cat > /etc/systemd/system/kyt.service << END
[Unit]
Description=Kyt Telegram Bot - @pian
After=network.target

[Service]
# Menggunakan direktori kerja yang benar
WorkingDirectory=$INSTALL_DIR/kyt
# Menjalankan modul python dari dalam direktorinya
ExecStart=/usr/bin/python3 -m kyt
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
END

# --- Menjalankan Service ---
echo "Menjalankan dan mengaktifkan service bot..."
# WAJIB: Memuat ulang konfigurasi systemd, lalu restart dan enable service
systemctl daemon-reload
systemctl restart kyt.service
systemctl enable kyt.service

# --- Selesai ---
cd /root
rm -f kyt.sh

echo "Instalasi selesai."
echo ""
echo "Data Bot Anda:"
echo -e "==============================="
echo "Token Bot    : $bottoken"
echo "Admin        : $admin"
echo "Domain       : $domain"
echo -e "==============================="
echo ""
echo "Pengaturan selesai. Ketik /menu di bot Telegram Anda."
