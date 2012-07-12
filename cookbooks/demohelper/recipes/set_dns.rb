#
# Cookbook Name:: demohelper
# Recipe:: default
#
# Copyright 2012, Cloudscaling, Inc.
#
# All rights reserved - Do Not Redistribute
#
# Read userdata passed to the VM is used to retrieve and set data bags on the hosted chef server.

# Make sure our custom GEM is preloaded for the recipe
g = cookbook_file "/tmp/dme-api-0.1.2.gem" do
  source "dme-api-0.1.2.gem"
  mode "0644"
  action :nothing
end
g.run_action(:create)

g = gem_package "dme-api" do
  action :nothing
  source "/tmp/dme-api-0.1.2.gem"
end
g.run_action(:install)
Gem.clear_paths
require 'dme-api'

# Add/Upate DNS records to DNSMadeEasy as VM's start up.
ruby_block "Update DNS" do
block  do
hostname = ""
  if node.set_dns == 'true'  then
    dme = DME.new(node[:dme][:apikey],node[:dme][:secretkey],node[:dme][:domain])
    case node.server_type
      when 'lb','loadbalancer'
        hostname = "www"
      when 'db'
        hostname = "db"
      else 
        hostname = "#{node['server_type']}"
    end 
#TODO(ROB): Need to make this OpenStack ready.
    public_ip = node.cloud.public_ipv4
    recordname = "#{hostname}.#{node['demo_name']}"
    record =  dme.get(recordname)
# If nil then create a new DNS entry.
    if record.nil? ||  node.server_type == 'lb' then
      record = { :name => recordname, :data => public_ip, :type => 'A', :ttl => '120' }
      dme.create(record)
    else
      record['data'] = public_ip
      dme.update(record['id'],record)
    end
  end

end # block do
  action :create
end # ruby_block
