#!/bin/bash

# =================================================================
# Skrip Otomatisasi DNS Cloudflare
#
# Deskripsi:
# Skrip ini membaca subdomain dari file, lalu membuat atau memperbarui
# A record untuk subdomain tersebut agar menunjuk ke IP publik server
# menggunakan API Cloudflare.
#
# Prasyarat:
# - File /root/subdomainx harus ada dan berisi nama subdomain.
# - jq dan curl harus terinstal.
# - Kredensial Cloudflare (Email dan Global API Key) harus valid.
# =================================================================

# --- Konfigurasi Awal ---
# Ganti dengan email dan Global API Key Cloudflare Anda
CF_ID="qwqw34207@gmail.com"
CF_KEY="266a89fba5c8824b989d663b382ba84f06d17"
# Ganti dengan domain utama Anda yang terdaftar di Cloudflare
DOMAIN="hahah.fun"

# --- Opsi Skrip ---
# Keluar dari skrip jika ada perintah yang gagal
set -euo pipefail

# --- Fungsi-Fungsi ---

# Fungsi untuk mendapatkan alamat IP publik server
get_public_ip() {
    echo "Mendapatkan IP publik..."
    IP=$(curl -sS ifconfig.me)
    if [[ -z "$IP" ]]; then
        echo "Gagal mendapatkan alamat IP publik. Keluar..."
        exit 1
    fi
    echo "IP Publik Server: ${IP}"
}

# Fungsi untuk mendapatkan Zone ID dari Cloudflare berdasarkan nama domain
get_cloudflare_zone_id() {
    echo "Mendapatkan Zone ID Cloudflare untuk domain ${DOMAIN}..."
    ZONE=$(curl -sLX GET "https://api.cloudflare.com/client/v4/zones?name=${DOMAIN}&status=active" \
        -H "X-Auth-Email: ${CF_ID}" \
        -H "X-Auth-Key: ${CF_KEY}" \
        -H "Content-Type: application/json" | jq -r .result[0].id)

    if [[ -z "$ZONE" || "$ZONE" == "null" ]]; then
        echo "Gagal mendapatkan Zone ID Cloudflare. Pastikan domain dan kredensial benar. Keluar..."
        exit 1
    fi
    echo "Zone ID ditemukan: ${ZONE}"
}

# Fungsi untuk membuat atau memperbarui DNS record
update_or_create_record() {
    local record_type=$1
    local name=$2
    local content=$3

    echo "Memeriksa DNS record untuk ${name}..."
    
    # Cek apakah record sudah ada
    local record_id=$(curl -sLX GET "https://api.cloudflare.com/client/v4/zones/${ZONE}/dns_records?type=${record_type}&name=${name}" \
        -H "X-Auth-Email: ${CF_ID}" \
        -H "X-Auth-Key: ${CF_KEY}" \
        -H "Content-Type: application/json" | jq -r .result[0].id)

    # Jika record_id kosong (null atau string kosong), berarti record belum ada
    if [[ "$record_id" == "null" || -z "$record_id" ]]; then
        echo "DNS record untuk ${name} tidak ditemukan, membuat record baru..."
        curl -sLX POST "https://api.cloudflare.com/client/v4/zones/${ZONE}/dns_records" \
            -H "X-Auth-Email: ${CF_ID}" \
            -H "X-Auth-Key: ${CF_KEY}" \
            -H "Content-Type: application/json" \
            --data '{"type":"'"${record_type}"'","name":"'"${name}"'","content":"'"${content}"'","ttl":120,"proxied":false}' | jq .
    else
        # Jika record sudah ada, perbarui
        echo "Memperbarui DNS record yang ada untuk ${name} (ID: ${record_id})..."
        curl -sLX PUT "https://api.cloudflare.com/client/v4/zones/${ZONE}/dns_records/${record_id}" \
            -H "X-Auth-Email: ${CF_ID}" \
            -H "X-Auth-Key: ${CF_KEY}" \
            -H "Content-Type: application/json" \
            --data '{"type":"'"${record_type}"'","name":"'"${name}"'","content":"'"${content}"'","ttl":120,"proxied":false}' | jq .
    fi
}

# Fungsi untuk menyimpan konfigurasi domain ke dalam file
save_configuration() {
    local domain_name=$1
    echo "Menyimpan konfigurasi..."
    
    # Pastikan direktori tujuan ada
    mkdir -p /etc/xray
    mkdir -p /etc/v2ray

    echo "${domain_name}" > /root/domain
    echo "${domain_name}" > /etc/xray/domain
    echo "${domain_name}" > /etc/v2ray/domain
    echo "IP=${domain_name}" > /var/lib/ipvps.conf
    echo "Konfigurasi berhasil disimpan."
}

# --- Fungsi Utama ---
main() {
    # Pastikan skrip dijalankan sebagai root
    if [ "$(id -u)" -ne 0 ]; then
        echo "Skrip ini harus dijalankan sebagai root. Coba gunakan 'sudo'."
        exit 1
    fi
    
    # Install dependensi jika belum ada
    if ! command -v jq &> /dev/null || ! command -v curl &> /dev/null; then
        echo "Menginstall dependensi (jq, curl)..."
        apt-get update && apt-get install -y jq curl
    fi

    # Baca subdomain dari file
    if [[ ! -f /root/subdomainx ]]; then
        echo "File /root/subdomainx tidak ditemukan. Keluar..."
        exit 1
    fi
    local sub=$(cat /root/subdomainx)
    if [[ -z "$sub" ]]; then
        echo "File /root/subdomainx kosong. Keluar..."
        exit 1
    fi
    
    local SUB_DOMAIN="${sub}.${DOMAIN}"
    echo "Subdomain yang akan diproses: ${SUB_DOMAIN}"

    get_public_ip
    get_cloudflare_zone_id

    # Buat atau perbarui A record untuk subdomain
    update_or_create_record "A" "${SUB_DOMAIN}" "${IP}"

    save_configuration "${SUB_DOMAIN}"

    echo "=========================================="
    echo "      Proses Konfigurasi Selesai"
    echo "=========================================="
    echo "Host      : ${SUB_DOMAIN}"
    echo "IP Server : ${IP}"
    echo "=========================================="
    
    # Beri jeda agar DNS sempat melakukan propagasi
    sleep 3
}

# Eksekusi fungsi utama
main
