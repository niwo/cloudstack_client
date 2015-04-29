require "cloudstack_client/api"
require "cloudstack_client/error"
require 'cloudstack_client/utils'
require "cloudstack_client/connection"

module CloudstackClient
  class Client < Connection
    include Utils
    attr_accessor :options
    attr_reader :api

    def initialize(api_url, api_key, secret_key, options = {})
      super(api_url, api_key, secret_key, options = {})
      unless options[:no_api_methods]
        @api = Api.new(options)
        define_api_methods
      end
    end

    def define_api_methods
      @api.commands.each do |command|
        method_name = camel_case_to_underscore(command.name).to_sym

        define_singleton_method(method_name) do |args = {}, options = {}|
          params = {"command" => command.name}

          args.each do |k, v|
            k = @api.normalize_key(k)
            if v != nil && @api.command_supports_param?(command, k)
              params[k] = v
            end
          end

          unless @api.all_required_params?(command, params)
            raise ParameterError, @api.missing_params_msg(command)
          end

          sync = command.isasync == false || options[:sync]
          sync ? send_request(params) : send_async_request(params)
        end
      end
    end

  end # class
end
