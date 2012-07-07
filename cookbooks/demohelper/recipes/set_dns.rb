#
# Cookbook Name:: demohelper
# Recipe:: default
#
# Copyright 2012, Cloudscaling, Inc.
#
# All rights reserved - Do Not Redistribute
#
# Read userdata passed to the VM is used to retrieve and set data bags on the hosted chef server.

domain = DNS::DME.new(node[:dme][:apikey],node[:dme][:secretkey])
info = { :domain => 'jdsdemo.com', :name => 'myservertest', :ip => node[:ipaddress], :type => 'A', :ttl => '85640' }
domain.record_add(info)


