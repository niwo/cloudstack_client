require "base64"
require "openssl"
require "uri"
require "cgi"
require "net/http"
require "json"

module CloudstackClient
  class Connection
    include Utils

    attr_accessor :api_url, :api_key, :secret_key, :verbose, :debug, :symbolize_keys, :host, :read_timeout
    attr_accessor :async_poll_interval, :async_timeout, :request_retries

    DEF_POLL_INTERVAL = 2.0
    DEF_ASYNC_TIMEOUT = 400
    DEF_REQ_TIMEOUT = 60
    DEF_REQUEST_RETRIES = 1

    def initialize(api_url, api_key, secret_key, options = {})
      @api_url = api_url
      @api_key = api_key
      @secret_key = secret_key
      @verbose = options[:quiet] ? false : true
      @debug = options[:debug] ? true : false
      @symbolize_keys = options[:symbolize_keys] ? true : false
      @host = options[:host]
      @read_timeout = options[:read_timeout] || DEF_REQ_TIMEOUT
      @async_poll_interval = options[:async_poll_interval] || DEF_POLL_INTERVAL
      @async_timeout = options[:async_timeout] || DEF_ASYNC_TIMEOUT
      @request_retries = options[:request_retries] || DEF_REQUEST_RETRIES
      @options = options
      validate_input!
    end

    ##
    # Sends a synchronous request to the CloudStack API and returns the response as a Hash.
    #

    def send_request(params, opts = {})
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
      http.read_timeout = @read_timeout

      retries = 0
      begin
        req = Net::HTTP::Get.new(uri.request_uri)
        req['Host'] = host if host.present?
        response = http.request(req)
      rescue => e
        retries += 1
        if retries < @request_retries
          sleep(retries) # incremental back-off
          retry
        end
        raise ConnectionError, "API URL \'#{@api_url}\' is not reachable (after #{retries} attempt#{'s' if retries > 1}): #{e.message}"
      end

      begin
        body = JSON.parse(response.body, symbolize_names: @symbolize_keys).values.first
      rescue JSON::ParserError
        raise ParseError,
              "Response from server is not readable. Check if the API endpoint (#{@api_url}) is valid and accessible."
      end

      if response.is_a?(Net::HTTPOK)
        return body unless body.respond_to?(:keys)
        if body.size == 2 && body.key?(k('count'))
          return opts[:include_count] ? body : body.reject { |key, _| key == k('count') }.values.first
        elsif body.size == 1 && body.values.first.respond_to?(:keys)
          item = body.values.first
          return (item.is_a?(Array) || item.is_a?(Hash)) ? item : []
        else
          body.reject! { |key, _| key == k('count') } if body.key?(k('count')) && !opts[:include_count]
          body.size == 0 ? [] : body
        end
      else
        message = body[k('errortext')] rescue body
        raise ApiError, "Status #{response.code}: #{message}."
      end
    end

    ##
    # Sends an asynchronous request and waits for the response.
    #
    # The contents of the 'jobresult' element are returned upon completion of the command.

    def send_async_request(params, opts = {})
      data = send_request(params, opts)

      params = {
        'command' => 'queryAsyncJobResult',
        'jobid' => data[k('jobid')]
      }

      max_tries.times do
        data = send_request(params)
        print "." if @verbose

        case data[k('jobstatus')]
        when 1
          return data[k('jobresult')]
        when 2
          raise JobError, "Request failed (#{data[k('jobresultcode')]}): #{data[k('jobresult')][k('errortext')]}."
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
      raise InputError, "REQUEST RETRIES must be at least 1." if @request_retries < 1
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
      CGI.escape(input.to_s)
        .gsub('+', '%20')
        .gsub(' ', '%20')
        .gsub('%2A', '*')
    end

    def symbolized_key(name)
      @symbolize_keys ? name.to_sym : name
    end
    alias_method :k, :symbolized_key

  end # class
end # module
