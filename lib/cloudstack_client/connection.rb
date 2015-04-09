require 'base64'
require 'openssl'
require 'uri'
require 'cgi'
require 'net/http'
require 'net/https'
require 'json'

module CloudstackClient
  class Connection

    @@async_poll_interval = 2.0
    @@async_timeout = 400

    attr_accessor :api_url, :api_key, :secret_key, :verbose, :debug

    def initialize(api_url, api_key, secret_key, options = {})
      @api_url = api_url
      @api_key = api_key
      @secret_key = secret_key
      @verbose = options[:quiet] ? false : true
      @debug = options[:debug] ? true : false
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
        raise ConnectionError, "API URL \'#{@api_url}\' is not reachable."
      end

      if response.is_a? Net::HTTPOK
        begin
          json = JSON.parse(response.body)
          json = json[params['command'].downcase + 'response']
        rescue JSON::ParserError
          raise ParseError, "Error parsing response from server: #{response.body}."
        end
      else
        json = JSON.parse(response.body)
        message = json[json.keys.first]['errortext'] rescue response.body
        raise ApiError, "Error #{response.code} - #{message}."
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
          raise JobError, "Request failed (#{json['jobresultcode']}). #{json['jobresult']}."
        end

        STDOUT.flush
        sleep @@async_poll_interval
      end

      raise TiemoutError, "Asynchronous request timed out."
    end

    private

    def debug_output(output, seperator = '-' * 80)
      puts
      puts seperator
      puts output
      puts seperator
      puts
    end

  end
end
