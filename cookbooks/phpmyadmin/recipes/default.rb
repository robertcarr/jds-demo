#
# Cookbook Name:: phpmyadmin
# Recipe:: default
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
#include_recipe "apache2"

%w[ git-core php5-mysql php5-mcrypt ].each { |p| package p }

cookbook_file "/var/www/rotator.png" do
  source "rotator.png"
  mode "0644"
end

cookbook_file "/var/www/index.html" do
  source "index.html"
  mode "0644"
end

cookbook_file "/tmp/phpmyadmin.tar.gz" do
  source "phpMyAdmin-3.5.2-english.tar.gz"
  mode "0644"
end

bash "Prepare phpMyAdmin files" do
  code <<-EOH
  tar zxvf /tmp/phpmyadmin.tar.gz -C /var/www
  cd /var/www
  ln -s phpMyAdmin-3.5.2-english phpmyadmin
  EOH
end

template "/var/www/phpmyadmin/config.inc.php" do
  source "config.inc.php.erb"
  mode "0644"
end


