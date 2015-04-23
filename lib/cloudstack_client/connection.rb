require 'base64'
require 'openssl'
require 'uri'
require 'cgi'
require 'net/http'
require 'net/https'
require 'json'

module CloudstackClient
  class Connection

    attr_accessor :api_url, :api_key, :secret_key, :verbose, :debug
    attr_accessor :async_poll_interval, :async_timeout

    def initialize(api_url, api_key, secret_key, options = {})
      @api_url = api_url
      @api_key = api_key
      @secret_key = secret_key
      @verbose = options[:quiet] ? false : true
      @debug = options[:debug] ? true : false
      @async_poll_interval = options[:async_poll_interval] || 2.0
      @async_timeout = options[:async_timeout] || 400
    end

    ##
    # Sends a synchronous request to the CloudStack API and returns the response as a Hash.
    #

    def send_request(params)
      params['response'] = 'json'
      params['apiKey'] = @api_key

      params_arr = params.sort.map do |key, value|
        value = CGI.escape(value.to_s).gsub('+', '%20').gsub(' ','%20')
        "#{key}=#{value}"
      end

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

      begin
        body = JSON.parse(response.body).values.first
      rescue JSON::ParserError
        raise ParseError, "Error parsing response from server: #{response.body}."
      end

      if response.is_a? Net::HTTPOK
        return body unless body.respond_to?(:keys)
        if body.size == 2 && body.key?('count')
          return body.reject { |key, _| key == 'count' }.values.first
        elsif body.size == 1 && body.values.first.respond_to?(:keys)
          item = body.values.first
          return item.is_a?(Array) ? item : []
        else
          response.size == 0 ? [] : body
        end
      else
        message = data[data.keys.first]['errortext'] rescue data
        raise ApiError, "Error #{response.code} - #{message}."
      end
    end

    ##
    # Sends an asynchronous request and waits for the response.
    #
    # The contents of the 'jobresult' element are returned upon completion of the command.

    def send_async_request(params)
      data = send_request(params)

      params = {
        'command' => 'queryAsyncJobResult',
        'jobid' => data['jobid']
      }

      max_tries.times do
        data = send_request(params)

        print "." if @verbose

        case data['jobstatus']
        when 1
          return data['jobresult']
        when 2
          raise JobError, "Request failed (#{data['jobresultcode']}). #{data['jobresult']}."
        end

        STDOUT.flush if @verbose
        sleep @async_poll_interval
      end

      raise TimeoutError, "Asynchronous request timed out."
    end

    private

    def max_tries
      (@async_timeout / @async_poll_interval).round
    end

    def debug_output(output, seperator = '-' * 80)
      puts
      puts seperator
      puts output
      puts seperator
      puts
    end

  end
end
