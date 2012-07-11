#!/usr/bin/ruby

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
      if d['demo_name'] == demo then
        return true
      end
    end
    return false
  end
  def show(demo)
    @config.each do |d|
      if d['demo_name'] == demo then
       d.to_yaml
      end
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
 meta = allinfo(demo)
  r = roles(demo)
  puts "Attempting to start and configure: #{demo}"
  base = 'knife ec2 server create'
  r.each do |server|
    fn = "/tmp/userdata_#{$$}.jds"
    userdata = "demo_name=#{meta['demo_name']}&server_role=#{server['role']}&userid=#{@userid}&set_dns=#{server['set_dns']}"
    File.open(fn, 'w') { |f| f.write(userdata) }
    cmd = base + " -x #{meta['login_user']} -S #{meta['ssh_key']} -G #{meta['security_group']} --image #{meta['image_id']} --flavor #{meta['machine_size']} " +
              "--user-data #{fn} --run-list role[#{server['role']}]"
    puts cmd
    system(cmd)
    sleep 5 
  File.delete(fn)
  end
  end 
  
  def allinfo(demo)
    @config.each do |d|
     return d if d['demo_name'] == demo
    end
    "Demo #{demo} not found!"
  end

end # end class JDS
@opt = {}
a = JDS.new
@opts = OptionParser.new do |o|
@opt[:dryrun] = false

  o.banner = "Usage: #{$0} [OPTIONS] <demo>"
  o.on("-h","--help","Help") { puts @opts }
  o.on("-l","--list","List available demos") { a.demos }
  o.on("-r","--roles DEMO","Show roles for a demo") { |role| puts a.roles(role) }
  o.on("-d","--dryrun","Displays execution steps without running them") { @opt[:dryrun] = true }
  o.on("-s","--start DEMO","Start the demo <DEMO>")  { |demo| a.run(demo) }
  o.on("-a","--allinfo DEMO","All metadata for demo DEMO") { |demo| puts a.allinfo(demo).to_json }
    
end

@opts.parse! ARGV

