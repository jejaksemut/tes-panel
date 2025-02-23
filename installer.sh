#!/bin/bash

# Pastikan script dijalankan sebagai root
if [ "$EUID" -ne 0 ]; then
  echo "Silakan jalankan sebagai root."
  exit
fi

# Update dan upgrade sistem
apt update && apt upgrade -y

# Instal dependensi yang diperlukan
apt install -y software-properties-common curl wget unzip

# Instal PHP dan ekstensi yang diperlukan
add-apt-repository ppa:ondrej/php -y
apt update
apt install -y php8.0 php8.0-cli php8.0-fpm php8.0-mysql php8.0-xml php8.0-mbstring php8.0-curl php8.0-zip php8.0-bcmath php8.0-json

# Instal MySQL
apt install -y mysql-server

# Amankan instalasi MySQL
mysql_secure_installation <<EOF

y
password
password
y
y
y
y
EOF

# Buat database untuk Pterodactyl
mysql -u root -ppassword -e "CREATE DATABASE pterodactyl;"
mysql -u root -ppassword -e "CREATE USER 'pterodactyl'@'localhost' IDENTIFIED BY 'password';"
mysql -u root -ppassword -e "GRANT ALL PRIVILEGES ON pterodactyl.* TO 'pterodactyl'@'localhost';"
mysql -u root -ppassword -e "FLUSH PRIVILEGES;"

# Instal Composer
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

# Instal Pterodactyl Panel
cd /var/www
curl -Lo panel.zip https://github.com/pterodactyl/panel/releases/latest/download/panel.zip
unzip panel.zip
mv panel/* /var/www/pterodactyl
rm -rf panel.zip panel

# Set permission
cd /var/www/pterodactyl
composer install --no-dev --optimize-autoloader
cp .env.example .env
php artisan key:generate

# Konfigurasi .env
sed -i 's/DB_HOST=127.0.0.1/DB_HOST=localhost/' .env
sed -i 's/DB_DATABASE=database_name/DB_DATABASE=pterodactyl/' .env
sed -i 's/DB_USERNAME=username/DB_USERNAME=pterodactyl/' .env
sed -i 's/DB_PASSWORD=password/DB_PASSWORD=password/' .env

# Migrasi database
php artisan migrate --seed --force

# Instal Wings
cd /var/www
mkdir wings
cd wings
curl -Lo wings.tar.gz https://github.com/pterodactyl/wings/releases/latest/download/wings.tar.gz
tar -xzf wings.tar.gz
rm wings.tar.gz

# Set permission untuk Wings
chmod +x wings
cp wings/config.yml.example wings/config.yml

# Konfigurasi Wings
# Edit wings/config.yml sesuai kebutuhan Anda
# Misalnya, Anda bisa menggunakan sed untuk mengubah pengaturan di config.yml

# Selesai
echo "Instalasi Pterodactyl Panel, Wings, dan MySQL selesai."
echo "Silakan sesuaikan konfigurasi di wings/config.yml dan atur web server Anda."
