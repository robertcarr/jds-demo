module DNS
require 'openssl'
require 'time'
  class DME
    def initialize(apikey, secretkey)
      @secretkey = secretkey
      @apikey = apikey
      @endpoint = 'http://api.dnsmadeeasy.com/V1.2'
      #@endpoint = 'http://api.dnsmadeeasy.com/V2.0'
    end

    def hmac
      OpenSSL::HMAC.hexdigest(OpenSSL::Digest::SHA1.new, @secretkey, Time.now.httpdate)
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
      @endpoint
    end
    def endpoint(url)
      @endpoint = url
    end
    def standardHeaders
      headers = Hash.new
      headers = { :apikey => "x-dnsme-apiKey:#{@apikey}", :date => "x-dnsme-requestDate:#{Time.now.httpdate}", :hmac => "x-dnsme-hmac:#{hmac}" }
    end
    def record_add(h)
      headers = standardHeaders
      query = "domains/#{h[:domain]}/records"
      json = %Q_{"name" : "#{h[:name]}", "type" : "#{h[:type]}", "data" :"#{h[:ip]}", "gtdLocation" : "DEFAULT", "ttl" : #{h[:ttl]} }_
      request = "#{@endpoint}/#{query} --header '#{headers[:apikey]}' --header '#{headers[:date]}' --header '#{headers[:hmac]}' -X POST -H accept:application/json -H content-type:application/json -d '#{json}'"
      #puts request
      `curl #{request}`
    end
    def get(*q)
      query = q[0] || 'domains/jdsdemo.com/records'
      headers = standardHeaders
      request = "#{@endpoint}/#{query} --header '#{headers[:apikey]}' --header '#{headers[:date]}' --header '#{headers[:hmac]}'"
      #puts request
      puts "curl #{request}"
      `curl #{request}`
    end
  end # end class DME
end # module DNS
