CHEF_CLIENT_INSTALL = <<-EOF
#!/bin/bash
test -d /opt/chef || {
	echo "Installing chef-client via RPM"
	#curl -L -s https://www.opscode.com/chef/install.sh | bash -s -- -v 11.16.4
    yum -y --disableplugin=fastestmirror install https://opscode-omnibus-packages.s3.amazonaws.com/el/6/x86_64/chef-11.16.4-1.el6.x86_64
	#yum -y --disableplugin=fastestmirror localinstall /vagrant/rpms/chef-11.16.4-1.el6.x86_64.rpm
}
EOF

CHEF_CLIENT_INIT = <<-EOF
#!/bin/bash

mkdir -p /etc/chef/trusted_certs
cp -f /vagrant/.chef/trusted_certs/* /etc/chef/trusted_certs

cat <<EOK > /etc/chef/client.rb
log_level        :auto
log_location     STDOUT
chef_server_url  "https://chef1.test.ld:443"
validation_client_name "chef-validator"
# Using default node name (fqdn)
encrypted_data_bag_secret "/etc/chef/encrypted_data_bag_secret"
trusted_certs_dir "/etc/chef/trusted_certs"
no_lazy_load    true
EOK
EOF

CHEF_SERVER_INSTALL = <<-EOF
#!/bin/bash

rpm -qa | grep chef-server
if [[ $? -ne 0 ]]
then
	echo "Installing Chef Server and Client via RPMs"
    yum -y --disableplugin=fastestmirror install https://opscode-omnibus-packages.s3.amazonaws.com/el/6/x86_64/chef-server-11.0.8-1.el6.x86_64.rpm https://opscode-omnibus-packages.s3.amazonaws.com/el/6/x86_64/chef-11.16.4-1.el6.x86_64.rpm https://opscode-omnibus-packages.s3.amazonaws.com/el/6/x86_64/chefdk-0.4.0-1.x86_64.rpm
	#yum -y --disableplugin=fastestmirror localinstall /vagrant/rpms/chef-server-11.0.8-1.el6.x86_64.rpm /vagrant/rpms/chef-11.16.4-1.el6.x86_64.rpm /vagrant/rpms/chefdk-0.4.0-1.x86_64.rpm
    chef-server-ctl reconfigure
	rm -rf "/vagrant/.chef" >/dev/null 2>&1
fi
EOF

CHEF_CREATE_ADMIN = <<-EOF
[ -f "/root/.chef/chef-webui.pem" ] && {
  # compare chef-validator.pem file, don't continue when it's already the same
  server_md5="$(md5sum /etc/chef-server/chef-validator.pem | cut -f1 -d' ')"
  client_md5="$(md5sum /root/.chef/chef-validator.pem | cut -f1 -d' ')"
  [ "$server_md5" = "$client_md5" ] && exit 0
}
echo "Creating workstation knife admin config"
mkdir -p /root/.chef
cp /etc/chef-server/chef-webui.pem /root/.chef/
cp /etc/chef-server/chef-validator.pem /root/.chef/
cat <<EOK > /root/.chef/knife.rb
cwd                     = File.dirname(__FILE__)
log_level               :info   # valid values - :debug :info :warn :error :fatal
log_location            STDOUT
node_name               ENV.fetch('KNIFE_NODE_NAME', 'chef-webui')
client_key              ENV.fetch('KNIFE_CLIENT_KEY', File.join(cwd, 'chef-webui.pem'))
chef_server_url         ENV.fetch('KNIFE_CHEF_SERVER_URL', 'https://chef1.test.ld')
validation_client_name  ENV.fetch('KNIFE_CHEF_VALIDATION_CLIENT_NAME', 'chef-validator')
validation_key          ENV.fetch('KNIFE_CHEF_VALIDATION_KEY', File.join(cwd,'chef-validator.pem'))
syntax_check_cache_path File.join(cwd,'syntax_check_cache')
EOK
knife ssl fetch
EOF

CHEF_CREATE_WORKSTATION = <<-EOF
#!/bin/bash

[ -f "/vagrant/.chef/chef-validator.pem" ] && {
  # compare chef-validator.pem file, don't continue when it's already the same
  server_md5="$(md5sum /etc/chef-server/chef-validator.pem | cut -f1 -d' ')"
  client_md5="$(md5sum /vagrant/.chef/chef-validator.pem | cut -f1 -d' ')"
  [ "$server_md5" = "$client_md5" ] && exit 0
}
echo "Creating workstation knife configuration"
mkdir -p /vagrant/.chef/trusted_certs
cp /etc/chef-server/chef-validator.pem /vagrant/.chef/
cp /root/.chef/trusted_certs/* /vagrant/.chef/trusted_certs/
knife client create vagrant -s https://chef1.test.ld -d -a -u chef-webui -k /etc/chef-server/chef-webui.pem -f /vagrant/.chef/vagrant.pem
cat <<EOK > /vagrant/.chef/knife.rb
cwd                     = File.dirname(__FILE__)
log_level               :info   # valid values - :debug :info :warn :error :fatal
log_location            STDOUT
node_name               ENV.fetch('KNIFE_NODE_NAME', 'vagrant')
client_key              ENV.fetch('KNIFE_CLIENT_KEY', File.join(cwd,'vagrant.pem'))
chef_server_url         ENV.fetch('KNIFE_CHEF_SERVER_URL', 'https://chef1.test.ld')
validation_client_name  ENV.fetch('KNIFE_CHEF_VALIDATION_CLIENT_NAME', 'chef-validator')
validation_key          ENV.fetch('KNIFE_CHEF_VALIDATION_KEY', File.join(cwd,'chef-validator.pem'))
syntax_check_cache_path File.join(cwd,'syntax_check_cache')
cookbook_path           File.join(cwd,'..','Chef','cookbooks')
data_bag_path           File.join(cwd,'..','Chef','data_bags')
role_path               File.join(cwd,'..','Chef','roles')
EOK
ln -s /vagrant/.chef /home/vagrant/
chown -R vagrant:vagrant /home/vagrant

#yum -y --disablerepo=epel localinstall /vagrant/rpms/epel-release-6-8.noarch.rpm
yum -y --disablerepo=epel install http://mirror.pnl.gov/epel/6/i386/epel-release-6-8.noarch.rpm
yum -y install vim git docker-io

usermod -a -G docker vagrant
service docker start
EOF

SETUP_GUEST = <<-EOF
#!/bin/bash

yum -y install vim git
EOF


VAGRANTFILE_API_VERSION = "2"
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.ssh.forward_agent = true
  config.vm.define "chef1", primary: true do |v|
    v.vm.provider "virtualbox" do |p|
      p.memory = 2048
      p.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    end
    v.vm.box = "chef/centos-6.6"
    v.vm.hostname = "chef1.test.ld"
    v.vm.network "private_network", ip: "192.168.248.101"
    v.vm.network "forwarded_port", guest: 443, host: 4000
    v.vm.provision :hosts
    v.vm.provision :shell, :inline => CHEF_SERVER_INSTALL
    v.vm.provision :shell, :inline => CHEF_CREATE_ADMIN
    v.vm.provision :shell, :inline => CHEF_CREATE_WORKSTATION
    #v.vm.provision :shell, :inline => SETUP_GUEST
    v.vm.provision :shell, :path => 'scripts/init-server.sh', privileged: false
  end
  config.vm.define "app1" do |v|
    v.vm.provider "virtualbox" do |p|
      p.memory = 512
      p.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    end
    v.vm.box = "chef/centos-6.6"
    v.vm.hostname = "app1.test.ld"
    v.vm.network "private_network", ip: "192.168.248.102"
    v.vm.provision :hosts
    v.vm.provision :shell, :inline => CHEF_CLIENT_INSTALL
    v.vm.provision :shell, :inline => CHEF_CLIENT_INIT
    v.vm.provision :shell, :inline => SETUP_GUEST
    v.vm.provision :shell, :path => "scripts/init-node.sh"
    v.vm.provision :chef_client do |chef|
      chef.chef_server_url = 'https://chef1.test.ld'
      chef.validation_key_path = '.chef/chef-validator.pem'
      chef.validation_client_name = 'chef-validator'
      chef.run_list = [
        # ... put something in here, or knife node edit app1.test.ld
      ]
    end
  end
end

