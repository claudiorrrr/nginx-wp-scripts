#!/bin/bash -e
clear
echo "============================================"
echo "WordPress Install Script"
echo "============================================"

# Gathering database login credentials from user input
read -sp "Your mysql root password: " rootpasswd
echo
read -p "Database Name: " dbname
read -p "Database User: " dbuser
# create random password
dbpass="$(openssl rand -base64 24)"
echo

# Create new database using provided credentials
read -p "Create new database with provided credentials? (y/n): " new_db
echo "Creating new MySQL database..."
mysql -uroot -p${rootpasswd} -e "CREATE DATABASE ${dbname} /*\!40100 DEFAULT CHARACTER SET utf8 */;"
echo "Creating new user..."
mysql -uroot -p${rootpasswd} -e "CREATE USER ${dbuser}@localhost IDENTIFIED BY '${dbpass}';"
echo "User successfully created!"
echo ""
echo "Granting ALL privileges on ${dbname} to ${dbuser}!"
mysql -uroot -p${rootpasswd} -e "GRANT ALL ON ${dbname}.* TO '${dbuser}'@'localhost';"
mysql -uroot -p${rootpasswd} -e "FLUSH PRIVILEGES;"
echo "MySQL DB / User creation completed!"

clear

echo "============================================"
echo "MYSQL db/user creation completed!"
echo " >> Database  : ${dbname}"
echo " >> User      : ${dbuser}"
echo " >> Pass      : ${dbpass}"
echo "============================================"

echo


# Starting the Wordpress installation process 
# option 2 doesn't work -- need fix
echo "==================================="
echo "Choose Wordpress installation mode:"
echo "==================================="
echo
echo "1. Install Wordpress using wp-cli"
echo "2. Install Wordpress without wp-cli"
echo
read -p "Choose install method: " install_method

if [ "$install_method" == 1 ]; then

	# Starting the Wordpress installation process using wp-cli
	echo "==================================="
	echo "Please wait while we install wp-cli"
	echo "==================================="
	curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
	chmod +x wp-cli.phar
	# linux:
	sudo cp wp-cli.phar /usr/bin/wp
	# macos: 
	# wp-cli.phar /usr/local/bin/wp

	echo "=========================="
	echo "Finished installing wp-cli"
	echo "=========================="
	echo
	read -p "Install wordpress in a new directory (y/n): " new


	read -p "Install wordpress in a new directory (y/n):  - new question " new;do
#
        if [ "$new" == y ] ; then
                echo "she said yes"
		break
               read -p "Name of the wordpress directory: " dir_name
               mkdir -p /var/www/$dir_name
               cd /var/www/$dir_name
        elif [ "$new" == n ]; then
		echo "she said no"
		break
fi
done

	# Download the latest wordpress package using wp-cli
	wp core download --allow-root
	# Creating wp-config file using credentials defined on lines 8-11
	wp core config --dbhost=localhost --dbname=$dbname --dbuser=$dbuser --dbpass=$dbpass --allow-root
	chmod 644 wp-config.php

	# Entering details of the new Wordpress site
	clear
	echo "======================================================="
	echo "Ready to install Wordpress. Just enter few more details"
	echo "======================================================="
	read -p "Website url: " url
	read -p "Website title: " title
	read -p "Admin username: " admin_name
	admin_pass="$(openssl rand -base64 24)"
	echo
	read -p "Admin email: " admin_email
	echo
	read -p "Run install? (y/n): " run_wp_install
	
	if [ "$run_wp_install" == n ] ; then
		exit
	else
		echo "============================================"
		echo "A robot is now installing WordPress for you."
		echo "============================================"
		echo
		# Installing Wordpress site using credentials defined on lines 71-76
		wp core install --url=$url --title="$title" --admin_name=$admin_name --admin_password=$admin_pass --admin_email=$admin_email --allow-root
	fi
else
	

	# download wordpress
	curl -O https://wordpress.org/latest.tar.gz
	# unzip wordpress
	tar -zxvf latest.tar.gz
	# change dir to wordpress
	cd wordpress
	# copy file to parent dir
	cp -rf . ..
	# move back to parent dir
	cd ..
	# remove files from wordpress folder
	rm -R wordpress
	# create wp config
	cp wp-config-sample.php wp-config.php
	# set database details with perl find and replace
	perl -pi -e "s/database_name_here/$dbname/g" wp-config.php
	perl -pi -e "s/username_here/$dbuser/g" wp-config.php
	perl -pi -e "s/password_here/$dbpass/g" wp-config.php

	# set WP salts
	perl -i -pe'
	   BEGIN {
	     @chars = ("a" .. "z", "A" .. "Z", 0 .. 9);
	     push @chars, split //, "!@#$%^&*()-_ []{}<>~\`+=,.;:/?|";
	     sub salt { join "", map $chars[ rand @chars ], 1 .. 64 }
	   }
	   s/put your unique phrase here/salt()/ge
	' wp-config.php

	# create uploads folder and set permissions
	mkdir wp-content/uploads
	chmod 775 wp-content/uploads
	echo "Cleaning..."
	# remove zip file
	rm latest.tar.gz


## for some reason this does not show at the end
	clear
	
	cat << EOF
 	============================================
	Installation is complete.
	============================================
	MYSQL db/user creation completed!
	Database  : ${dbname}
	User      : ${dbuser}
	Pass      : ${dbpass}
	============================================
	"Wordpress install completed!
	Domain  	: ${url}
	Email  	: ${admin_email}
	User      : ${admin_name}
	Pass      : ${admin_pass}
	============================================
	
EOF

fi
done