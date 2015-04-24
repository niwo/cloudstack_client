require 'base64'
require 'openssl'
require 'uri'
require 'cgi'
require 'net/http'
require 'net/https'
require 'json'
require 'yaml'

module CloudstackClient
  class Connection

    @@async_poll_interval = 2.0
    @@async_timeout = 400

    # include all commands
    Dir.glob(File.dirname(__FILE__) + "/commands/*.rb").each do |file|
      require file
      module_name = File.basename(file, '.rb').split('_').map{|f| f.capitalize}.join
      include Object.const_get("CloudstackClient").const_get(module_name)
    end

    attr_accessor :verbose
    attr_accessor :debug

    def initialize(api_url, api_key, secret_key, opts = {})
      @api_url = api_url
      @api_key = api_key
      @secret_key = secret_key
      @verbose = opts[:quiet] ? false : true
      @debug = opts[:debug] ? true : false
    end

    ##
    # Sends a synchronous request to the CloudStack API and returns the response as a Hash.
    #
    # The wrapper element of the response (e.g. mycommandresponse) is discarded and the
    # contents of that element are returned.

    def send_request(params)
      params['response'] = 'json'
      params['apiKey'] = @api_key

      params_arr = []
      params.sort.each { |elem|
        params_arr << elem[0].to_s + '=' + CGI.escape(elem[1].to_s).gsub('+', '%20').gsub(' ','%20')
      }

      debug_output JSON.pretty_generate(params) if @debug

      data = params_arr.join('&')
      signature = OpenSSL::HMAC.digest('sha1', @secret_key, data.downcase)
      signature = Base64.encode64(signature).chomp
      signature = CGI.escape(signature)

      url = "#{@api_url}?#{data}&signature=#{signature}"

      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)

      if uri.scheme == 'https'
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end

      begin
        response = http.request(Net::HTTP::Get.new(uri.request_uri))
      rescue
        puts "Error connecting to API:"
        puts "#{@api_url} is not reachable"
        exit 1
      end


      if response.is_a? Net::HTTPOK
        begin
          json = JSON.parse(response.body)
          json = json[params['command'].downcase + 'response']
        rescue JSON::ParserError
          puts "Error parsing response from server:"
          puts response.body
          exit 2
        end
      else
        begin
          json = JSON.parse(response.body)
          puts "Error executing command..."
          puts json if @debug
          json = json[params['command'].downcase + 'response']
          puts "#{json['errorcode']}: #{json['errortext']}"
        rescue
          puts "Error parsing response from server..."
          puts "#{response.code}: #{response.body}"
        end
        exit 3
      end
    end

    ##
    # Sends an asynchronous request and waits for the response.
    #
    # The contents of the 'jobresult' element are returned upon completion of the command.

    def send_async_request(params)

      json = send_request(params)

      params = {
          'command' => 'queryAsyncJobResult',
          'jobId' => json['jobid']
      }

      max_tries = (@@async_timeout / @@async_poll_interval).round
      max_tries.times do
        json = send_request(params)
        status = json['jobstatus']

        print "." if @verbose

        if status == 1
          return json['jobresult']
        elsif status == 2
          puts
          puts "Request failed (#{json['jobresultcode']}): #{json['jobresult']}"
          exit 1
        end

        STDOUT.flush
        sleep @@async_poll_interval
      end

      print "\n"
      puts "Error: Asynchronous request timed out"
      exit 1
    end

    private

    def debug_output(output, seperator = '-' * 80)
      puts
      puts seperator
      puts output
      puts seperator
      puts
    end

  end # class
end
