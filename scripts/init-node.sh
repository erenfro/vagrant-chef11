#!/usr/bin/env bash

rpm -qa | grep vim >/dev/null 2>&1
if [[ $? -eq 1 ]]
then
	yum -y install vim
fi

if [[ -f "/vagrant/secrets/encrypted_data_bag_secret" && ! -f "/etc/chef/encrypted_data_bag_secret" ]]
then
    if [[ ! -d "/etc/chef" ]]
    then
    	mkdir -p /etc/chef
    fi
    cp /vagrant/secrets/encrypted_data_bag_secret /etc/chef/encrypted_data_bag_secret
    chmod go-rwx /etc/chef/encrypted_data_bag_secret
    chown root:root /etc/chef/encrypted_data_bag_secret
else
    echo "Encrypted Data Bag Secret is not in the secrets directory" >&2
    sleep 5
fi

