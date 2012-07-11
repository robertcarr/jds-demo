#
# Cookbook Name:: demohelper
# Recipe:: default
#
# Copyright 2012, Cloudscaling, Inc.
#
# All rights reserved - Do Not Redistribute
#
# Read userdata passed to the VM is used to retrieve and set data bags on the hosted chef server.


params = Hash.new

ohai_data = node.current_automatic
cloud_data = ohai_data['cloud']

unless ohai_data['ec2']['userdata'].nil? then
cloud_data['userdata'] = ohai_data['ec2']['userdata']
    cloud_data['userdata'].split("&").each do |item|
    item = item.split("=")
    params[item[0]] = item[1].chomp
  end
end

demo_name = params['demo_name']
userid = params['userid']
server_role = params['server_role'] 
server_name = params['server_name'] || "notset"
dbag_name = "tenant_#{userid}_#{demo_name}"
set_dns = params['set_dns']

begin
# Need to grab the demo from userdata or file
customer_data = data_bag_item(dbag_name, "demo")

rescue
# No databag? Create one.
data = { 'id' => 'demo', 'public_ips' => [], 'private_ips' => [], 'public_dns' => nil, 'private_dns' => nil, 'servers' => [] }
dbag = Chef::DataBag.new ; dbag.name(dbag_name) ; dbag.save
dbag = Chef::DataBagItem.new ; dbag.data_bag(dbag_name) ; dbag.raw_data = data
dbag.save

# reload data after saving
customer_data = data_bag_item(dbag_name, "demo")
end

# Update the databags with the relvant network information.  This will allow the other services
# to find and connect when they are spun up.
unless customer_data.nil? || cloud_data.nil? 
  cloud_data.merge!({'server_name' => server_name, 'server_role'=>server_role, 'launched' => Time.now })
  customer_data['servers'] << cloud_data
  customer_data.save
end

# Read the entire data bag for this demo and create node variables that 
# can be helpful to the recipes that follow.

# TODO(ROB): move to library?
customer_data = data_bag_item(dbag_name, "demo")

@nodeinfo = Hash.new{|h,k| h[k]=[] }
customer_data['servers'].each do |server|
    @nodeinfo[server['server_role']]  << server
end

def attributes_by_role(role, attrib)
items = Array.new
 @nodeinfo[role].each do |server|
   items << server[attrib]
 end
 items
end

# Create node attributes that will persist to the recipes that follow this one.  This makes it easier & faster for the other other recipes to know about their 
# environment without having to query the chef server.
%w[ demo_name server_role userid set_dns server_name ].each { |x| eval("node.set[x] = eval(x)") }

@nodeinfo.each_key do |role|
  %w[ private_ips public_ips name server_role public_hostname local_hostname server_name ].each do |attrib|
    node.set["#{role}"]["#{attrib}"] = attributes_by_role(role, attrib)
  end
end
