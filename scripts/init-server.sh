#!/bin/bash

if [[ ! -d "/vagrant/Chef" ]]
then
	mkdir -p /vagrant/Chef
	mkdir -p /vagrant/Chef/{cookbooks,certificates}

    pushd ${HOME} 2>&1
    ln -s /vagrant/Chef
    popd 2>&1

    if [[ -f "/vagrant/secrets/encrypted_data_bag_secret" ]]
    then
        if [[ ! -f "/vagrant/.chef/encrypted_data_bag_secret" ]]
        then
            cp /vagrant/secrets/encrypted_data_bag_secret /vagrant/.chef/encrypted_data_bag_secret
            chmod go-rwx /vagrant/.chef/encrypted_data_bag_secret
        fi
    fi

    echo 'eval "$(chef shell-init bash)"' >> ${HOME}/.bash_profile

    chef gem install kitchen-docker
fi

