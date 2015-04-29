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
      define_api_methods unless options[:no_api_methods]
    end

    def define_api_methods
      Api.new(api_file: @api_file, api_version: @api_version).commands.each do |command|
        method_name = camel_case_to_underscore(command.name).to_sym

        define_singleton_method(method_name) do |args = {}, options = {}|
          params = {"command" => command.name}

          args.each do |k, v|
            k = normalize_key(k)
            if v != nil && command_supports_key?(command, k)
              params[k] = v
            end
          end

          unless all_required_args?(command, params)
            raise ArgumentError, missing_args_msg(command)
          end

          sync = command.isasync == false || options[:sync]
          sync ? send_request(params) : send_async_request(params)
        end
      end
    end

    def command_supports_key?(command, key)
      command.params.detect { |p| p["name"] == key }
    end

    def required_args(command)
      command.params.map do |param|
        param["name"] if param["required"] == true
      end.compact
    end

    def all_required_args?(command, args)
      required_args(command).all? {|k| args.key? k}
    end

    private

    def normalize_key(key)
      key.to_s.gsub("_", "")
    end

    def missing_args_msg(command)
      requ = required_args(command)
      "#{command.name} requires the following argument#{ 's' if requ.size > 1}: #{requ.join(', ')}"
    end

    def camel_case_to_underscore(camel_case)
      camel_case.gsub(/::/, '/').
        gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
        gsub(/([a-z\d])([A-Z])/,'\1_\2').
        tr("-", "_").downcase
    end

  end # class
end
