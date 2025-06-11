#!/bin/bash

# Оновлення системи та встановлення необхідного
apt update -y
apt install -y nginx php php-mysql php-redis php-fpm unzip wget curl git

# Завантаження та встановлення WordPress
cd /var/www/html
wget https://wordpress.org/latest.zip
unzip latest.zip
cp -r wordpress/* .
rm -rf wordpress latest.zip

# Налаштування прав доступу
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

# Копіюємо wp-config-sample.php → wp-config.php
cp wp-config-sample.php wp-config.php

# Підставляємо ЗНАЧЕННЯ ПРЯМО у wp-config.php
sed -i "s/database_name_here/${db_name}/" wp-config.php
sed -i "s/username_here/${db_user}/" wp-config.php
sed -i "s/password_here/${db_password}/" wp-config.php
sed -i "s/localhost/${db_host}/" wp-config.php

# Додаємо Redis конфіг перед require_once
sed -i "/require_once/i\\
define('WP_REDIS_HOST', '${redis_host}');" wp-config.php

# NGINX конфіг для сайту
cat <<EOF > /etc/nginx/sites-available/wordpress
server {
    listen 80;
    server_name _;

    root /var/www/html;
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php-fpm.sock;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

# Активація сайту
ln -s /etc/nginx/sites-available/wordpress /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
rm -f /etc/nginx/sites-avalible/default
systemctl disable apache2
systemctl stop apache2
systemctl restart nginx
