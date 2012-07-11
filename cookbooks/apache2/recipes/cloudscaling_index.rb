cookbook_file "/var/www/rotator.png" do
  source "rotator.png"
  mode "0644"
end

cookbook_file "/var/www/index.html" do
  source "index.html"
  mode "0644"
end

