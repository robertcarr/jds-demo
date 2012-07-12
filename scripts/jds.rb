#!/usr/bin/ruby
#
# jds.rb
# Simple CLI to interact with the Cloudscaling JDS Demo system.
#
#
require 'json'
require 'optparse'

class JDS
  def initialize
    begin
      puts "Retrieving metadata..."
      @userid = ENV['JDS_USERID'] || '666'
      json = JSON.parse((`knife environment show jds --format json`).gsub('json_class','demo'))
      @config = json['default_attributes']['demos']
    rescue
      puts "Error loading environment data.  Is knife command installed?"
      exit
    end
  end
  def demos
    puts "Available Demos: "
    puts "Name\t\t\tDescription"
    @config.each do |d|
      tab =  " " * ( 24 - d['demo_name'].length)
      printf("%s#{tab}%s\n", d['demo_name'], d['description'])
    end
  end
  def exists?(demo)
    @config.each do |d|
      d['demo_name'] == demo ? true  : false
    end
  end
  def show(demo)
    @config.each do |d|
      return d.to_yaml if d['demo_name'] == demo 
    end
  end
  def roles(demo)
  role = []
    @config.each do |d|
      if d['demo_name'] == demo then
        d['roles'].each do |r|
        role << r
        end
      end
    end 
    role
  end
  def run(demo)
  lb = false
  db = false
    begin
    `knife data bag delete tenant_#{@userid}_#{demo} -y`
    rescue
    end
    meta = allinfo(demo)
    puts "Running demo #{demo}.  This may take a bit."
    base = 'knife ec2 server create'
    r=roles(demo)
    r.each do |server|
    server['server_type'] == 'lb' ? lb = true : lb = false
    server['server_type'] == 'db' ? db = true : db = false
      puts "Starting #{server['qty']} #{server['server_role']}"
      fn = "/tmp/userdata_#{$$}.jds"
      userdata = "demo_name=#{meta['demo_name']}&userid=#{@userid}&"
      userdata << server.collect { |k,v| "#{k}=#{v}" }.join("&")
      cmd = base + " -x #{meta['login_user']} -S #{meta['ssh_key']} -G #{meta['security_group']} --image #{meta['image_id']} --flavor #{meta['machine_size']}"
      cmd <<  " --user-data #{fn} --run-list role[#{server['server_role']}]"
      File.open(fn, 'w') { |f| f.write(userdata) }
      cmd = "seq #{server['qty']} | parallel -n0 -j0 -v \"#{cmd}\""
      `#{cmd}`
      sleep 5 
      File.delete(fn)
    end
    base_url = "#{meta['demo_name']}.jdsdemo.com"
    puts "Done!"
    puts "Your demo is ready at http://www.#{base_url}" if lb
    puts "HAProxy Statistics at http://www.#{base_url}:22002/" if lb
    puts "DB is at http://db.#{base_url}" if db
    puts "Monitoring is at http://monitoring.#{base_url}"
  end 
 
  def running
   @data = system("knife ec2 server list | egrep '(running|pending)'")
  end
  def killall
   @data = system("knife ec2 server list | egrep '(running|pending)' | awk '{print $1;}'")
  end
  def kill(id)
    system("knife ec2 server delete #{id} -P -y")
  end
  
  def allinfo(demo)
    @config.each do |d|
     return d if d['demo_name'] == demo
    end
    "Demo #{demo} not found!"
  end

end # end class JDS
if ARGV.length != 0 ; a = JDS.new ; end
@opt = {}
@opts = OptionParser.new do |o|
@opt[:dryrun] = false
  o.banner = "Usage: #{$0} [OPTIONS] <demo>"
  o.on("-h","--help","Help") { puts @opts }
  o.on("--kill ID", "Kill instance <ID>") { |id| a.kill(id) }
  o.on("-l","--list","List available demos") { a.demos }
  o.on("-r","--roles DEMO","Show roles for a demo") { |role| puts a.roles(role) }
  o.on("--running","Running instances") { a.running }
  o.on("-d","--dryrun","Displays execution steps without running them") { @opt[:dryrun] = true }
  o.on("-s","--start DEMO","Start the demo <DEMO>")  { |demo| a.run(demo) }
  o.on("-a","--allinfo DEMO","All metadata for demo DEMO") { |demo| puts a.allinfo(demo).to_json }
end

@opts.parse! ARGV


