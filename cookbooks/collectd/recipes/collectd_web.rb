#
# Cookbook Name:: collectd
# Recipe:: collectd_web
#
# Copyright 2010, Atari, Inc
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe "collectd"
include_recipe "apache2"

directory node[:collectd][:collectd_web][:path] do
  owner "root"
  group "root"
  mode "755"
end

%w[ librrds-perl libjson-perl ].each do |p|
package p 
end

bash "install_collectd_web" do
  user "root"
  cwd node[:collectd][:collectd_web][:path]
  not_if do
    File.exists?(File.join(node[:collectd][:collectd_web][:path], "index.html"))
  end
  code <<-EOH
    wget --no-check-certificate -O collectd-web.tar.gz https://github.com/httpdss/collectd-web/tarball/master
    tar --strip-components=1 -xzf collectd-web.tar.gz
    rm collectd-web.tar.gz
  EOH
end

template "/etc/apache2/sites-available/collectd_web.conf" do
  source "collectd_web.conf.erb"
  owner "root"
  group "root"
  mode  "0644"
end

cookbook_file "/srv/collectd_web/index.html" do
  source "index.html"
  mode "0644"
  owner "root"
  group "root"
end

cookbook_file "/srv/collectd_web/media/images/rotator-small.png" do
  source "rotator-small.png"
  mode "0644"
  owner "root"
  group "root"
end

cookbook_file "/srv/collectd_web/.htaccess" do 
  source "htaccess"
  mode "0644"
  owner "root"
  group "root"
end

bash "added .htaccess file" do
  user "root"
  code <<-EOH
  htpasswd -bc /srv/collectd_web/.htpasswd cs "#{node[:collectd][:collectd_web][:htpasswd]}"
  EOH
end


apache_site "default" do
  enable false
end

bash "allow overrides" do
  user "root"
  code <<-EOH
  sed -i 's/AllowOverride None/AllowOverride All/g' /etc/apache2/sites-available/collectd_web.conf
  EOH
end

apache_site "collectd_web.conf"
