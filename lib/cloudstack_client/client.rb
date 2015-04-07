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

    attr_accessor :verbose, :debug, :api_version

    def initialize(api_url, api_key, secret_key, options = {})
      @api_url = api_url
      @api_key = api_key
      @secret_key = secret_key
      @api_version = options[:api_version] if options[:api_version]
      @api_file = options[:api_file] if options[:api_file]
      @verbose = options[:quiet] ? false : true
      @debug = options[:debug] ? true : false
      define_api_methods() unless options[:no_api_methods]
    end

    def define_api_methods
      Api.new(api_file: @api_file, api_version: @api_version).commands.each do |command|
        method_name = underscore(command.name).to_sym

        define_singleton_method(method_name) do |args = {}, options = {}|
          params = {"command" => command.name}

          args.each do |key, value|
            params[key.to_s.gsub("_", "")] = value
          end

          response = if command.isasync == false || options[:sync]
            send_request(params)
          else
            send_async_request(params)
          end

          return [] unless response.respond_to?(:keys)

          if response.size == 2 && response.key?("count")
            response.reject { |key, _| key == "count" }.values.first
          elsif response.size == 1 && response.values.first.respond_to?(:keys)
            response.values.first
          else
            response.size == 0 ? [] : response
          end
        end
      end
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

    def underscore(camel_case)
      camel_case.gsub(/::/, '/').
        gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
        gsub(/([a-z\d])([A-Z])/,'\1_\2').
        tr("-", "_").
        downcase
    end

  end # class
end
