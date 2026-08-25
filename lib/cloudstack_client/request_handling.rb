module CloudstackClient
  module RequestHandling
    def send_request(params, opts = {})
      params['response'] = 'json'
      params['apiKey'] = @api_key
      print_debug_output JSON.pretty_generate(params) if @debug

      data = params_to_data(params)
      uri = URI.parse "#{@api_url}?#{data}&signature=#{create_signature(data)}"
      http = build_http(uri)
      response = request_with_retries(http, uri)

      handle_response(response, opts)
    end

    private

    def build_http(uri)
      http = Net::HTTP.new(uri.host, uri.port)
      return configure_https(http) if uri.scheme == 'https'

      http.read_timeout = @read_timeout
      http
    end

    def configure_https(http)
      http.use_ssl = true
      http.verify_mode = @verify_ssl ? OpenSSL::SSL::VERIFY_PEER : OpenSSL::SSL::VERIFY_NONE
      http.ca_file = @ca_file if @ca_file
      http.read_timeout = @read_timeout
      http
    end

    def request_with_retries(http, uri)
      retries = 0
      begin
        request = Net::HTTP::Get.new(uri.request_uri)
        request['Host'] = host unless host.to_s.strip.empty?
        http.request(request)
      rescue Errno::ECONNREFUSED, Errno::ECONNRESET, Errno::EHOSTUNREACH,
             Errno::ENETUNREACH, Errno::ETIMEDOUT, Net::OpenTimeout,
             Net::ReadTimeout, SocketError, EOFError => e
        retries += 1
        if retries < @request_retries
          sleep(retries)
          print "." if @verbose
          retry
        end
        raise ConnectionError,
              "API URL '#{@api_url}' is not reachable " \
              "(after #{retries} attempt#{'s' if retries > 1}): #{e.message}"
      end
    end

    def handle_response(response, opts)
      body = parse_response_body(response)
      return normalize_success(body, opts) if response.is_a?(Net::HTTPOK)

      message = body.is_a?(Hash) ? body[k('errortext')] : body
      raise ApiError, "Status #{response.code}: #{message}."
    end

    def parse_response_body(response)
      JSON.parse(response.body, symbolize_names: @symbolize_keys).values.first
    rescue JSON::ParserError
      raise ParseError,
            "Response from server is not readable. Check if the API endpoint " \
            "(#{@api_url}) is valid and accessible."
    end

    def normalize_success(body, opts)
      return body unless body.respond_to?(:keys)
      return normalize_counted_response(body, opts) if body.size == 2 && body.key?(k('count'))
      return normalize_nested_response(body) if body.size == 1 && body.values.first.respond_to?(:keys)

      body.reject! { |key, _| key == k('count') } if body.key?(k('count')) && !opts[:include_count]
      body.empty? ? [] : body
    end

    def normalize_counted_response(body, opts)
      return body if opts[:include_count]

      body.reject { |key, _| key == k('count') }.values.first
    end

    def normalize_nested_response(body)
      item = body.values.first
      item.is_a?(Array) || item.is_a?(Hash) ? item : []
    end
  end
end
