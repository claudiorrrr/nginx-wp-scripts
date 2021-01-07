#!/usr/bin/env bash
#
# Nginx - new server block
# http://rosehosting.com
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

# Create nginx config file
cat > $NGINX_AVAILABLE_VHOSTS/$domain.conf <<EOF
### www to non-www
#server {
#    listen  80;
#    server_name  www.$domain;
#    return  301 http://$domain\$request_uri;
#}

server {
    listen   80;
    server_name $domain www.$domain;
    root  /var/www/$domain;
    charset  utf-8;
    index index.php index.html index.htm;

    #access_log $WEB_DIR/logs/$domain-access.log;
    access_log off;

    error_log $WEB_DIR/logs/$domain-error.log;
    #error_log off;


    ## REWRITES BELOW ##
    
    ## INCLUDE COMMONS ##

    include php.conf;
    include errors.conf;
    include drop.conf;
    include expires.conf;
}
EOF

# Creating {public,log} directories
mkdir -p $WEB_DIR/$username/{public_html,logs}

# Create nginx config file
cat > $NGINX_AVAILABLE_VHOSTS/$domain.conf <<EOF
### www to non-www
#server {
#    listen      80;
#    server_name  www.$domain;
#    return      301 http://$domain\$request_uri;
#}

server {
    listen   80;
    server_name $domain www.$domain;
    root  /var/www/$domain;
    charset  utf-8;
    index index.php index.html index.htm;

    #access_log /logs/$domain-access.log;
    access_log off;

    error_log /var/www/$domain/logs/$domain-error.log;
    #error_log off;


    ## REWRITES BELOW ##

    ## INCLUDE COMMONS ##

    include php.conf;
    include errors.conf;
    include drop.conf;
    include expires.conf;
}
EOF

mkdir -p /var/www/$domain
mkdir -p /var/www/$domain/logs

# Creating {public,log} directories
# mkdir -p $WEB_DIR/{public_html,logs}

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

# Restart
echo "Do you wish to restart nginx?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) service nginx restart ; break;;
        No ) exit;;
    esac
done

ok "Site Created for $domain"