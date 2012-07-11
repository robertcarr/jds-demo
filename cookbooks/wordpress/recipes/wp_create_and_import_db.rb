cookbook_file "/tmp/wordpress.sql" do
  source "wordpress.sql"
  mode "0644"
end

template "/tmp/demo_grants.sql" do
  source "demo_grants.sql.erb"
  mode "0644"
  variables(
    :password => node['mysql']['server_root_password']
  )
end

bash "Create db and import dump" do
  code <<-EOH
  mysqladmin -uroot -p"#{node.mysql.server_root_password}" create wordpressdb
  sed -i "s/server_role.demo/www."#{node.demo_name}"/g" /tmp/wordpress.sql
  mysql wordpressdb -uroot -p"#{node.mysql.server_root_password}" < /tmp/wordpress.sql
  mysql -uroot -p"#{node.mysql.server_root_password}" < /tmp/demo_grants.sql
  EOH
end
  
