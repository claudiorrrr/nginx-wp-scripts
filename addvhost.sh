#!/usr/bin/env bash
#
# Nginx - new server block
# Fork from: http://rosehosting.com
# Edited by: claudioruiz

read -p "Enter domain name : " domain
read -p "Enter username : " username

# Functions
ok() { echo -e '\e[32m'$domain'\e[m'; } # Green
die() { echo -e '\e[1;31m'$domain'\e[m'; exit 1; }

# Variables
NGINX_AVAILABLE_VHOSTS='/etc/nginx/sites-available'
NGINX_ENABLED_VHOSTS='/etc/nginx/sites-enabled'
WEB_DIR='/var/www/$domain'
WEB_USER=$username

# Sanity check
[ $(id -g) != "0" ] && die "Script must be run as root."
#[ $# != "1" ] && die "Usage: $(basename $0) domainName"

# Creating /var/www/ directory
mkdir -p /var/www/$domain

# Creating {public,log} directories
mkdir -p /var/www/$domain/logs
touch -p /var/www/$domain/logs/$domain.log

# Create nginx config file
cat > $NGINX_AVAILABLE_VHOSTS/$domain.conf <<EOF
server {
    listen   80;
    server_name $domain www.$domain;
    root  /var/www/$domain;
    charset  utf-8;
    index index.php index.html index.htm;

    #access_log $WEB_DIR/logs/$domain-access.log;
    access_log off;

    error_log /var/www/$domain/logs/$domain.log;
    #error_log off;

    location ~ \.php$ {
                include snippets/fastcgi-php.conf;
        #
        #       # With php7.0-cgi alone:
        #       # fastcgi_pass 127.0.0.1:9000;
        #       # With php7.0-fpm:
                fastcgi_pass unix:/run/php/php7.4-fpm.sock;
        }
}
EOF

# I need to figure out how to make this creation of a file conditional 
# in case the user would like to avoid creating the index.html... TBD

# Creating index.html file
cat > /var/www/$domain/index.html <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
        <title>$domain</title>
        <meta charset="utf-8" />
</head>
<body class="container">
        <header><h1>$domain<h1></header>
        <div id="wrapper"><p>Hello World, it works!</p></div>
</body>
</html>
EOF

# Changing permissions
chown -R $WEB_USER:www-data /var/www/$domain/

# Enable site by creating symbolic link
ln -s $NGINX_AVAILABLE_VHOSTS/$domain.conf $NGINX_ENABLED_VHOSTS/

# SSL
echo "============================================"
echo "SSL install"
echo "============================================"

# install certbot + python3-certbot-nginx 
sudo apt install certbot python3-certbot-nginx
sudo ufw allow 'Nginx Full'
sudo ufw delete allow 'Nginx HTTP'

# Restart
echo "Do you wish to restart nginx?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) service nginx restart ; break;;
        No ) exit;;
    esac
done

echo "============================================"
echo "please run 'sudo certbot --nginx -d $domain -d www.$domain' at the end"
echo "============================================"

ok "Site Created for $domain"