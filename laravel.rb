# -*- mode: ruby -*-
# vi: set ft=ruby :

# Apache Installation
puts "Installing Apache"
execute "sudo apt update"
['apache2', 'libapache2-mod-php7.2', 'php7.2', 'php7.2-gd', 'php7.2-dev', 'php7.2-curl', 'php7.2-mbstring', 'php7.2-mysql', 'php-zip'].each do |p|
  package p do
    action :install
  end
end
# MySQL Password
puts "Setting Password"
execute "sudo echo 'mysql-server mysql-server/root_password password tinnitus' | debconf-set-selections"
execute "sudo echo 'mysql-server mysql-server/root_password_again password tinnitus' | debconf-set-selections"
# MySQL Installation
puts "Installing MySQL"
package 'mysql-server'
# Starting Service
puts "Starting MySQL"
service 'mysql' do
  supports :status => true, :restart => true, :reload => true
  action [:enable, :start]
end
# Database User
puts "Creating User"
execute "mysql -u root -ptinnitus < /vargant/user.sql"
# Fetching Laravel
puts "Downloading Laravel"
execute "installComposer" do
  command "curl -Ss https://getcomposer.org/installer | php"
  user "vagrant"
  cwd "/tmp"
  environment 'HOME' => '/home/vagrant'
end
# Laravel Installation
puts "Installing Laravel"
execute "sudo mv /tmp/composer.phar /usr/bin/composer"
execute "installLaravel" do
  command "composer global require laravel/installer"
  user "vagrant"
  environment 'HOME' => '/home/vagrant'
end
# Changing Ownership
puts "Changing Permissions"
execute "sudo chown -R vagrant:vagrant /var/www"
execute "createProject" do
  command "composer create-project --prefer-dist laravel/laravel myProject"
  user "vagrant"
  cwd "/var/www"
  environment 'HOME' => '/home/vagrant'
end
execute "chmod -R 777 /var/www/myProject/storage"
execute "sudo sed -i 's/DocumentRoot.*/DocumentRoot \\/var\\/www\\/myProject\\/public/g' /etc/apache2/sites-available/000-default.conf"
# User Database
puts "Creating Database"
execute "sed -i '/mysql/{n;n;n;n;s/'\\''DB_DATABASE'\\'', '\\'',*'\\''/'\\''DB_DATABASE'\\'', '\\''myproject'\\''/g}' /var/www/myProject/config/database.php"
execute "sed -i '/mysql/{n;n;n;n;n;s/'\\''DB_USERNAME'\\'', '\\'',*'\\''/'\\''DB_USERNAME'\\'', '\\''myproject'\\''/g}' /var/www/myProject/config/database.php"
execute "sed -i '/mysql/{n;n;n;n;n;n;s/'\\''DB_PASSWORD'\\'', '\\'',*'\\''/'\\''DB_PASSWORD'\\'', '\\''logmein'\\''/g}' /var/www/myProject/config/database.php"
# Restarting Service
puts "Restarting Apache"
service 'apache2' do
  supports :status => true, :restart => true, :reload => true
  action [:enable, :restart]
end
# Laravel Interface
puts "Laravel Access: http://localhost:8080"
