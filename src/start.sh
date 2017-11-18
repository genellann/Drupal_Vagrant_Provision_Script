#!/usr/bin/env bash

if [ ! -f Vagrantfile ]; then
    vagrant init -m bento/ubuntu-16.04
    grep -v 'end' Vagrantfile > temp
    mv temp Vagrantfile
    echo '  config.vm.hostname = "web-dev"' >> Vagrantfile 
    echo '  config.vm.provision "shell", path: "provision.sh"' >> Vagrantfile
    echo '  config.vm.network "forwarded_port", guest: 80, host: 8080, id: "apache", auto_correct: true' >> Vagrantfile
    echo '  config.vm.network "private_network", ip: "192.168.33.111"' >> Vagrantfile
    echo 'end' >> Vagrantfile
fi

vagrant up

