#!/bin/bash
curl -s https://raw.githubusercontent.com/bangpateng/symphony/main/logo.sh | bash
sleep 5

# Fungsi untuk menampilkan pesan kesalahan dan keluar
function error_exit {
    echo "$1" >&2
    exit 1
}

# Cek apakah Docker sudah diinstal
if command -v docker &> /dev/null; then
    echo "Docker sudah terinstal."
else
    echo "Docker belum terinstal. Memulai instalasi Docker..."
    sudo apt-get update || error_exit "Gagal memperbarui daftar paket."
    sudo apt-get install -y docker.io || error_exit "Gagal menginstal Docker."

    # Cek ulang apakah Docker berhasil diinstal
    if ! command -v docker &> /dev/null; then
        error_exit "Docker tidak ditemukan setelah instalasi."
    else
        echo "Docker berhasil diinstal."
    fi
fi

# Menginstal Docker Compose
echo "Menginstal Docker Compose..."
DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4) || error_exit "Gagal mendapatkan versi Docker Compose."
sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose || error_exit "Gagal mengunduh Docker Compose."
sudo chmod +x /usr/local/bin/docker-compose || error_exit "Gagal mengatur izin eksekusi untuk Docker Compose."

# Cek apakah Docker Compose berhasil diinstal
if ! command -v docker-compose &> /dev/null; then
    error_exit "Docker Compose tidak ditemukan setelah instalasi."
else
    echo "Docker Compose berhasil diinstal."
fi

# Cek status Docker dan tampilkan log
echo "Memeriksa status Docker dan menampilkan log..."
sudo systemctl status docker || error_exit "Gagal memeriksa status Docker."
sudo journalctl -u docker --no-pager -n 100 || error_exit "Gagal menampilkan log Docker."

# Clone repositori
echo "Mengkloning repositori dkn-compute-node..."
git clone https://github.com/Winnode/dkn-compute-node || error_exit "Gagal mengkloning repositori."
cd dkn-compute-node || error_exit "Gagal masuk ke direktori dkn-compute-node."

# Menyalin file environment
cp .env.example .env || error_exit "Gagal menyalin file .env.example."

# Meminta input untuk private key dan OpenAI API key
read -sp "Masukkan YOUR_PRIVATE_KEY: " PRIVATE_KEY
echo
read -sp "Masukkan YOUR_OPENAI_API_KEY: " OPENAI_API_KEY
echo

# Menambahkan kunci ke file .env
{
    echo "DKN_WALLET_SECRET_KEY=$PRIVATE_KEY"
    echo "OPENAI_API_KEY=$OPENAI_API_KEY"
} >> .env || error_exit "Gagal menambahkan kunci ke file .env."

# Menjadikan skrip start.sh executable
chmod +x start.sh || error_exit "Gagal mengatur izin eksekusi untuk start.sh."

# Menampilkan bantuan untuk start.sh
./start.sh --help || error_exit "Gagal menjalankan ./start.sh --help."

# Menjalankan node compute dengan mode yang ditentukan
./start.sh -m=gpt-4o-mini || error_exit "Gagal menjalankan ./start.sh dengan mode gpt-4o-mini."
