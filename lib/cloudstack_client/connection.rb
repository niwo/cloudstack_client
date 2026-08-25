require "base64"
require "openssl"
require "uri"
require "cgi"
require "net/http"
require "json"
require "cloudstack_client/request_handling"

module CloudstackClient
  class Connection
    include Utils
    include RequestHandling

    attr_reader :api_key, :secret_key
    attr_accessor :api_url, :verbose, :debug, :symbolize_keys, :host, :read_timeout
    attr_accessor :verify_ssl, :ca_file
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
      @verify_ssl = options.fetch(:verify_ssl, true)
      @ca_file = options[:ca_file]
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

    ##
    # Sends an asynchronous request and waits for the response.
    #
    # The contents of the 'jobresult' element are returned upon completion of the command.

    def send_async_request(params, opts = {})
      request_timeout = opts[:async_timeout] || @async_timeout
      poll_interval = opts[:async_poll_interval] || @async_poll_interval
      validate_async_timeouts!(request_timeout, poll_interval)

      data = send_request(params, opts)

      params = {
        'command' => 'queryAsyncJobResult',
        'jobid' => data[k('jobid')]
      }

      max_tries(request_timeout, poll_interval).times do
        data = send_request(params)
        print "." if @verbose

        case data[k('jobstatus')]
        when 1
          return data[k('jobresult')]
        when 2
          result = data[k('jobresult')]
          error_text = result.is_a?(Hash) ? result[k('errortext')] : nil
          error_text ||= "Unknown error"
          raise JobError,
                "Request failed (#{data[k('jobresultcode')]}): #{error_text}."
        end

        STDOUT.flush if @verbose
        sleep poll_interval
      end

      raise TimeoutError, "Asynchronous request timed out."
    end

    private

    def validate_input!
      raise InputError, "API URL not set." if @api_url == nil
      raise InputError, "API KEY not set." if @api_key == nil
      raise InputError, "API SECRET KEY not set." if @secret_key == nil
      validate_async_timeouts!(@async_timeout, @async_poll_interval)
      raise InputError, "REQUEST RETRIES must be at least 1." if @request_retries < 1
    end

    def validate_async_timeouts!(timeout, interval)
      raise InputError, "ASYNC POLL INTERVAL must be at least 1." if interval < 1.0
      raise InputError, "ASYNC TIMEOUT must be at least 60." if timeout < 60
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

    def max_tries(timeout, interval)
      (timeout / interval).round
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
