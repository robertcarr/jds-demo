module DNS
require 'openssl'
  class DME
  @@endpoint = 'http://api.dnsmadeeasy.com/V1.2'
  #@@endpoint = 'http://api.dnsmadeeasy.com/V2.0'
    def initialize(apikey, secretkey)
      @secretkey = secretkey
      @apikey = apikey
    end

    def hmac
      OpenSSL::HMAC.hexdigest(OpenSSL::Digest::SHA1.new, @secretkey, httpdate)
    end
    def secretkey(key)
      @secretkey = key
    end
    def secretkey?
      @secretkey
    end
    def apikey(key)
      @apikey = key
    end
    def apikey?
      @apikey
    end
    def endpoint?
      @@endpoint
    end
    def httpdate
      t = Time.now
      t.gmtime.strftime("%a, %d %b %Y %H:%M:%S %Z")
    end
    def standardHeaders
      headers = Hash.new
      headers = { :apikey => "x-dnsme-apiKey:#{@apikey}", :date => "x-dnsme-requestDate:#{httpdate}", :hmac => "x-dnsme-hmac:#{hmac}" }
    end
    def record_add(h)
      headers = standardHeaders
      query = "domains/#{h[:domain]}/records"
      json = %Q_{"name" : "#{h[:name]}", "type" : "#{h[:type]}", "data" :"#{h[:ip]}", "gtdLocation" : "DEFAULT", "ttl" : #{h[:ttl]} }_
      request = "#{@@endpoint}/#{query} --header '#{headers[:apikey]}' --header '#{headers[:date]}' --header '#{headers[:hmac]}' -X POST -H accept:application/json -H content-type:application/json -d '#{json}'"
      #puts request
      `curl #{request}`
    end
    def send(*q)
      query = q[0] || 'domains/jdsdemo.com/records'
      headers = standardHeaders
      request = "#{@@endpoint}/#{query} --header '#{headers[:apikey]}' --header '#{headers[:date]}' --header '#{headers[:hmac]}'"
      #puts request
      puts "curl #{request}"
      `curl #{request}`
    end
  end # end class DME
end # module DNS
