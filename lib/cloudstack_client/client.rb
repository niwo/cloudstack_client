require "cloudstack_client/api"
require "cloudstack_client/error"
require "cloudstack_client/connection"

module CloudstackClient
  class Client < Connection

    attr_accessor :api_version, :api_path

    def initialize(api_url, api_key, secret_key, options = {})
      super(api_url, api_key, secret_key, options = {})
      @api_version = options[:api_version] if options[:api_version]
      @api_file = options[:api_file] if options[:api_file]
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

          if response.size == 2 && response.key?("count")
            response.reject { |key, _| key == "count" }.values.first
          elsif response.size == 1 && response.respond_to?(:keys)
            response.reject { |key, _| key == "count" }.values
          else
            response.size == 0 ? [] : response
          end
        end
      end
    end

    private

    def underscore(camel_case)
      camel_case.gsub(/::/, '/').
        gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
        gsub(/([a-z\d])([A-Z])/,'\1_\2').
        tr("-", "_").
        downcase
    end

  end # class
end
