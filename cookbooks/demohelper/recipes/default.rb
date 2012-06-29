#
# Cookbook Name:: demohelper
# Recipe:: default
#
# Copyright 2012, Cloudscaling, Inc.
#
# All rights reserved - Do Not Redistribute
#

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

puts params.inspect

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
