require "base64"
require "openssl"
require "uri"
require "cgi"
require "net/http"
require "json"

module CloudstackClient
  class Connection
    include Utils

    attr_accessor :api_url, :api_key, :secret_key, :verbose, :debug
    attr_accessor :async_poll_interval, :async_timeout

    DEF_POLL_INTERVAL = 2.0
    DEF_ASYNC_TIMEOUT = 400

    def initialize(api_url, api_key, secret_key, options = {})
      @api_url = api_url
      @api_key = api_key
      @secret_key = secret_key
      @verbose = options[:quiet] ? false : true
      @debug = options[:debug] ? true : false
      @async_poll_interval = options[:async_poll_interval] || DEF_POLL_INTERVAL
      @async_timeout = options[:async_timeout] || DEF_ASYNC_TIMEOUT
      @options = options
      validate_input!
    end

    ##
    # Sends a synchronous request to the CloudStack API and returns the response as a Hash.
    #

    def send_request(params)
      params['response'] = 'json'
      params['apiKey'] = @api_key
      print_debug_output JSON.pretty_generate(params) if @debug

      data = params_to_data(params)
      uri = URI.parse "#{@api_url}?#{data}&signature=#{create_signature(data)}"

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
        raise ParseError,
          "Response from server is not readable. Check if the API endpoint (#{@api_url}) is valid and accessible."
      end

      if response.is_a?(Net::HTTPOK)
        return body unless body.respond_to?(:keys)
        if body.size == 2 && body.key?('count')
          return body.reject { |key, _| key == 'count' }.values.first
        elsif body.size == 1 && body.values.first.respond_to?(:keys)
          item = body.values.first
          return (item.is_a?(Array) || item.is_a?(Hash)) ? item : []
        else
          body.reject! { |key, _| key == 'count' } if body.key?('count')
          body.size == 0 ? [] : body
        end
      else
        message = body['errortext'] rescue body
        raise ApiError, "Status #{response.code}: #{message}."
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
          raise JobError, "Request failed (#{data['jobresultcode']}): #{data['jobresult']['errortext']}."
        end

        STDOUT.flush if @verbose
        sleep @async_poll_interval
      end

      raise TimeoutError, "Asynchronous request timed out."
    end

    private

    def validate_input!
      raise InputError, "API URL not set." if @api_url == nil
      raise InputError, "API KEY not set." if @api_key == nil
      raise InputError, "API SECRET KEY not set." if @secret_key == nil
      raise InputError, "ASYNC POLL INTERVAL must be at least 1." if @async_poll_interval < 1.0
      raise InputError, "ASYNC TIMEOUT must be at least 60." if @async_timeout < 60
    end

    def params_to_data(params)
      params_arr = params.sort.map do |key, value|
        case value
        when Array # support for maps (Arrays of Hashes)
          map = []
          value.each_with_index do |items, i|
            items.each {|k, v| map << "#{key}[#{i}].#{k}=#{escape(v)}"}
          end
          map.sort.join("&")
        when Hash # support for maps values of values (Hash values of Hashes)
          value.each_with_index.map do |(k, v), i|
            "#{key}[#{i}].key=#{escape(k)}&" +
            "#{key}[#{i}].value=#{escape(v)}"
          end.join("&")
        else
          "#{key}=#{escape(value)}"
        end
      end
      params_arr.sort.join('&')
    end

    def create_signature(data)
      signature = OpenSSL::HMAC.digest('sha1', @secret_key, data.downcase)
      signature = Base64.encode64(signature).chomp
      CGI.escape(signature)
    end

    def max_tries
      (@async_timeout / @async_poll_interval).round
    end

    def escape(input)
      CGI.escape(input.to_s).gsub('+', '%20').gsub(' ', '%20')
    end

  end # class
end # module
