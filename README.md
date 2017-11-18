# Drupal_Vagrant_Provision_Script
Provisioning script for spinning up a vagrant box with a fresh instance of Drupal 8 on it.

Vagrant allows you to create portable work environments which can be easily reproduced on any system. 

What is provisioning
What is Drupal
https://drupalize.me/videos/why-vagrant?p=1526 

1. [Download VirtualBox](https://www.virtualbox.org/wiki/Downloads)
2. [Download Vagrant](https://www.vagrantup.com/downloads.html)
3. Clone or download this git repository: _git clone git@github.com:genradley/Drupal_Vagrant_Provision_Script.git_
4. Make sure the [start](/src/start.sh) and [provision](/src/provision.sh) scripts have execution permissions: _chmod a+x_
5. In unix shell, run the [start](/src/start.sh) script: _./start.sh_

## [start.sh](/src/start.sh)

The start script: 
(1) initializes a ubuntu 16.04 VirtualBox, and 
(2) tells the [Vagrantfile](https://www.vagrantup.com/docs/vagrantfile/) to use the provisioning script and what port or ip to run  on

Check to see if a Vagrantfile exists:

    if [ ! -f Vagrantfile ]; then

Initialize bento/ubuntu-16.04:

        vagrant init -m bento/ubuntu-16.04

Add config settings to Vagrantfile:
Either localhost:8080 or private network ip

        grep -v 'end' Vagrantfile > temp
        mv temp Vagrantfile
        echo '  config.vm.hostname = "web-dev"' >> Vagrantfile 
        echo '  config.vm.provision "shell", path: "provision.sh"' >> Vagrantfile
        echo '  config.vm.network "forwarded_port", guest: 80, host: 8080, id: "apache", auto_correct: true' >> Vagrantfile
        echo '  config.vm.network "private_network", ip: "192.168.33.111"' >> Vagrantfile
        echo 'end' >> Vagrantfile
    fi
 
Start vagrant. This will run the provision script the first time the vagrant box is brought up.

    vagrant up

## [provision.sh](/src/provision.sh)

### Update apt-get
Before we do anything, we need to make sure apt-get is up-to-date.
    
    apt-get update

### Install LAMP
From [Drupal 8 System Requirements](https://www.drupal.org/docs/8/system-requirements): "Drupal 8 works on any web server with PHP version of 5.5.9 or greater... Apache is the most commonly used web server for Drupal." 

I am using a LAMP (Linux, Apache, MySql, PHP) stack here. 

Set up the script to automatically insert MySql password:

    apt-get install -y debconf-utils
    debconf-set-selections <<< "mysql-server mysql-server/root_password password $DB_PASS"
    debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $DB_PASS"

Install LAMP:

    apt-get install -y lamp-server^
    apt-get install -y php-xml php7.0-gd php7.0-mbstring zip unzip php7.0-zip #Drupal dependencies not installed by lamp-server

### Install Composer
    wget https://getcomposer.org/composer.phar
    chmod +x composer.phar
    mv composer.phar /usr/local/bin/composer

### Install Drush
    wget https://github.com/drush-ops/drush-launcher/releases/download/0.3.1/drush.phar
    chmod +x drush.phar
    mv drush.phar /usr/local/bin/drush

### Download Drupal
It is recommended that Drupal 8 sites be built using Composer, with Drush listed as a dependency. 
http://docs.drush.org/en/8.x/install/ https://github.com/drupal-composer/drupal-project

    cd /var/www/html
    rm -rf *
    mkdir $APP_NAME
    composer create-project drupal-composer/drupal-project:8.x-dev $APP_NAME --stability dev --no-interaction

### Install Drupal
https://drushcommands.com/drush-8x/core/site-install/

    cd $APP_NAME/web
    drush site-install -y standard --account-name=$ACCT_NAME --account-pass=$ACCT_PASS --account-mail=$ACCT_EMAIL --db-url=mysql://$DB_USER:$DB_PASS@$DB_HOST/$DB_NAME --site-name=$APP_NAME

### Configure Server
https://www.linode.com/docs/websites/cms/install-and-configure-drupal-8

Drupal 8 enables [Clean URLs](https://www.drupal.org/getting-started/clean-urls) by default so Apache’s rewrite module must also be enabled:
    
    a2enmod rewrite

Specify the DocumentRoot:

    sed -i "s+DocumentRoot /var/www/html+DocumentRoot /var/www/html/$APP_NAME/web+" /etc/apache2/sites-available/000-default.conf
    
Specify the rewrite conditions for DocumentRoot in Apache’s configuration file:
    
    sed -i 's/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf
   
Change ownership of Apache’s DocumentRoot from the system’s root user to Apache. This allows you to install modules and themes, and to update Drupal, all without being prompted for FTP credentials.

    chown --recursive vagrant:www-data /var/www/html/$APP_NAME
    chmod --recursive g+w /var/www/html/$APP_NAME

Restart Apache so all changes are applied:

    service apache2 restart
    
## Start Using Drupal
May be virtual box change
Installing modules/themes
Git
Vagrant commands - ssh
If the something doesn't go right and you need to modify the scripts and start over: vagrant destroy, rm -rf .vagrant Vagrantfile then run ./start.sh again