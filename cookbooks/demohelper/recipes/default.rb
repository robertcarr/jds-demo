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

cloud_data.merge!({'server_role'=>params['server_role'], 'launched' => Time.now })

begin
# Need to grab the demo from userdata or file
customer_data = data_bag_item(params['userid'], "demo")
rescue
end

# Update the databags with the relvant network information.  This will allow the other services
# to find and connect when they are spun up.

unless customer_data.nil? || cloud_data.nil? 
  customer_data['demos'].each do |demo|
if demo['name'] == params['demo_name'] then
            demo['servers'] << cloud_data
    end
    customer_data.save
  end
end




# Read the entire data bag for this demo and create node variables that 
# can be helpful to the recipes that follow.

# TODO(ROB): move to library?

customer_data = data_bag_item(params['userid'], "demo")

@nodeinfo = Hash.new{|h,k| h[k]=[] }

customer_data['demos'].each do |demo|
  if demo['name'] == params['demo_name']
    demo['servers'].each do |server|
    @nodeinfo[server['server_role']]  << server
    end
  end
end

def attributes_by_role(role, attrib)
items = Array.new
 @nodeinfo[role].each do |server|
   items << server[attrib]
 end
 items
end

h= Hash.new{ |h,k| h[k]=[] }
node.set['demo'] = params['demo_name']
node.set['server_role'] = params['server_role']

@nodeinfo.each_key do |role|
  %w[ private_ips public_ips name server_role public_hostname local_hostname ].each do |attrib|
    node.set["#{role}"]["#{attrib}"] = attributes_by_role(role, attrib)
  end
end

