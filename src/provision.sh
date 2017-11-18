#!/usr/bin/env bash

APP_NAME=mysite
DB_HOST=localhost
DB_NAME=mysite_db
DB_USER=root
DB_PASS=p@ssc0d3
ACCT_NAME=admin
ACCT_PASS=admin
ACCT_EMAIL=example@example.com

echo " ------------- PROVISION SCRIPT START ------------- "

echo " ------------- UPDATING APT-GET ------------- "
apt-get update

echo " ------------- INSTALLING LAMP ------------- "
apt-get install -y debconf-utils
debconf-set-selections <<< "mysql-server mysql-server/root_password password $DB_PASS"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $DB_PASS"

apt-get install -y lamp-server^
apt-get install -y php-xml php7.0-gd php7.0-mbstring zip unzip php7.0-zip #Drupal dependencies not installed by lamp-server

echo " ------------- INSTALLING COMPOSER ------------- "
wget https://getcomposer.org/composer.phar
chmod +x composer.phar
mv composer.phar /usr/local/bin/composer

echo " ------------- INSTALLING DRUSH ------------- "
wget https://github.com/drush-ops/drush-launcher/releases/download/0.3.1/drush.phar
chmod +x drush.phar
mv drush.phar /usr/local/bin/drush

echo " ------------- DOWNLOADING DRUPAL ------------- "
cd /var/www/html
rm -rf *
mkdir $APP_NAME
composer create-project drupal-composer/drupal-project:8.x-dev $APP_NAME --stability dev --no-interaction

echo " ------------- INSTALLING DRUPAL ------------- "
cd $APP_NAME/web
drush site-install -y standard --account-name=$ACCT_NAME --account-pass=$ACCT_PASS --account-mail=$ACCT_EMAIL --db-url=mysql://$DB_USER:$DB_PASS@$DB_HOST/$DB_NAME --site-name=$APP_NAME

echo " ------------- CONFIGURING SERVER ------------- "
a2enmod rewrite
sed -i "s+DocumentRoot /var/www/html+DocumentRoot /var/www/html/$APP_NAME/web+" /etc/apache2/sites-available/000-default.conf
sed -i 's/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf
chown --recursive vagrant:www-data /var/www/html/$APP_NAME
chmod --recursive g+w /var/www/html/$APP_NAME
service apache2 restart

echo " ------------- INSTALLING GIT ------------- "
apt-get install -y git

echo " ------------- PROVISION SCRIPT END ------------- "