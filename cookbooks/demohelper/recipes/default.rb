#
# Cookbook Name:: demohelper
# Recipe:: default
#
# Copyright 2012, Cloudscaling, Inc.
#
# All rights reserved - Do Not Redistribute
#

begin
# Need to grab the demo from userdata or file
customer_data = data_bag_item("user", "demo")
rescue
end


user_data = Hash['demo_name' => 'demo1']
server_role = 'other'

ohai_data = node.current_automatic
cloud_data = ohai_data['cloud']
cloud_data.merge!({'server_role'=>server_role})


# TODO(ROB): Add to get userdata or file information from openstack as well
unless cloud_data.nil? 
if cloud_data['provider']= 'ec2'
        cloud_data['userdata'] = ohai_data['ec2']['userdata']
end
end

# Update the databags with the relvant network information.  This will allow the other services
# to find and connect when they are spun up.

unless customer_data.nil? || cloud_data.nil? 
  customer_data['demos'].each do |demo|
    if demo['name'] == user_data['demo_name'] then
            demo['servers'] << cloud_data
    end
    customer_data.save
  end
end
