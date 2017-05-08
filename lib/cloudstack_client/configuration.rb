module CloudstackClient
  require "yaml"

  module Configuration
    def self.load(configuration)
      unless File.exists?(configuration[:config_file])
        message = "Configuration file '#{configuration[:config_file]}' not found."
        raise message
      end
      begin
        config = YAML::load(IO.read(configuration[:config_file]))
      rescue => e
        message = "Can't load configuration from file '#{configuration[:config_file]}'."
        message += "Message: #{e.message}" if configuration[:debug]
        message += "Backtrace:\n\t#{e.backtrace.join("\n\t")}" if configuration[:debug]
        raise message
      end

      env ||= config[:default]
      if env
        unless config = config[env]
          raise "Can't find environment #{env}."
        end
      end

      unless config.key?(:url) && config.key?(:api_key) && config.key?(:secret_key)
        message = "The environment #{env || '\'-\''} does not contain all required keys."
        raise message
      end
      config.merge(environment: env)
    end
  end
end
