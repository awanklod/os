#!/bin/bash

# =================================================================
# Skrip Otomatisasi DNS Cloudflare
#
# Deskripsi:
# Skrip ini secara otomatis membuat subdomain acak untuk domain utama,
# mengarahkan subdomain tersebut (A record) ke IP publik server,
# dan membuat subdomain nameserver (NS record) yang menunjuk ke
# subdomain utama menggunakan API Cloudflare.
#
# Prasyarat:
# - jq dan curl harus terinstal.
# - Kredensial Cloudflare (Email dan Global API Key) harus valid.
# =================================================================

# --- Konfigurasi Awal ---
# Ganti dengan email dan Global API Key Cloudflare Anda
CF_ID="qwqw34207@gmail.com"
CF_KEY="266a89fba5c8824b989d663b382ba84f06d17"
# Ganti dengan domain utama Anda yang terdaftar di Cloudflare
DOMAIN="hahah.fun"

# --- Fungsi-Fungsi ---

# Fungsi untuk membersihkan dan menyiapkan direktori yang dibutuhkan
prepare_directories() {
    echo "Menyiapkan direktori..."
    rm -rf /root/xray/scdomain
    mkdir -p /root/xray
    clear
}

# Fungsi untuk menghasilkan subdomain acak
generate_random_subdomains() {
    echo "Membuat subdomain acak..."
    local sub=$(</dev/urandom tr -dc a-z0-9 | head -c5)
    local subsl=$(</dev/urandom tr -dc a-z0-9 | head -c5)
    
    SUB_DOMAIN="${sub}.${DOMAIN}"
    NS_DOMAIN="${subsl}.ns.${DOMAIN}"
    echo "Subdomain yang dibuat: ${SUB_DOMAIN}"
    echo "NS Domain yang dibuat: ${NS_DOMAIN}"
}

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

    if [[ -z "$ZONE" ]]; then
        echo "Gagal mendapatkan Zone ID Cloudflare. Pastikan domain dan kredensial benar. Keluar..."
        exit 1
    fi
    echo "Zone ID ditemukan: ${ZONE}"
}

# Fungsi untuk membuat atau memperbarui DNS record (A atau NS)
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
    echo "Menyimpan konfigurasi..."
    echo "IP=${SUB_DOMAIN}" > /var/lib/ipvps.conf
    echo "${SUB_DOMAIN}" > /root/domain
    echo "${NS_DOMAIN}" > /root/dns
    
    # Pastikan direktori /etc/xray ada
    mkdir -p /etc/xray
    
    echo "${SUB_DOMAIN}" > /etc/xray/domain
    echo "${NS_DOMAIN}" > /etc/xray/dns
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

    prepare_directories
    generate_random_subdomains
    get_public_ip
    get_cloudflare_zone_id

    # Buat atau perbarui A record untuk subdomain utama
    update_or_create_record "A" "${SUB_DOMAIN}" "${IP}"

    # Buat atau perbarui NS record untuk subdomain nameserver
    update_or_create_record "NS" "${NS_DOMAIN}" "${SUB_DOMAIN}"

    save_configuration

    echo "=========================================="
    echo "      Proses Konfigurasi Selesai"
    echo "=========================================="
    echo "Host      : ${SUB_DOMAIN}"
    echo "Host NS   : ${NS_DOMAIN}"
    echo "IP Server : ${IP}"
    echo "=========================================="
    
    # Beri jeda agar DNS sempat melakukan propagasi
    sleep 3
}

# Eksekusi fungsi utama
main

