# # Cookbook Name:: demohelper # Recipe:: default # # Copyright 2012, YOUR_COMPANY_NAME # # All rights reserved - Do Not Redistribute # # Need to parse userdata to form the databag name # # account = node.ec2.userdata
account="user"
demo_name='demo1'

node.account = data_bag_item(account, "demo")

node.account['demos'].each do |demo|
puts demo['name']

if demo['name'] == demo_name
node[:demo][:app] = Array.new
node[:demo][:db] = Array.new
node[:demo][:lb] = Array.new

  demo['servers'].each do |server|
    case server['type']
      when 'application'
       puts "app=#{server[:name]}"
        node[:demo][:app].push(server)
      when 'lb'
        node[:demo][:lb].push(server)
      when 'db'
        node[:demo][:db].push(server)
    end
  end
end
end
