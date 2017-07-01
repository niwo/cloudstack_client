module CloudstackClient
  require "yaml"

  module Configuration

    def self.load(configuration)
      file = configuration[:config_file] || Configuration.locate_config_file
      unless File.exists?(file)
        raise ConfigurationError, "Configuration file '#{file}' not found."
      end

      begin
        config = YAML::load(IO.read file)
      rescue => e
        message = "Can't load configuration from file '#{file}'."
        if configuration[:debug]
          message += "\nMessage: #{e.message}"
          message += "\nBacktrace:\n\t#{e.backtrace.join("\n\t")}"
        end
        raise message
      end

      if env ||= config[:default]
        unless config = config[env]
          raise ConfigurationError, "Can't find environment #{env}."
        end
      end

      unless config.key?(:url) && config.key?(:api_key) && config.key?(:secret_key)
        message = "The environment #{env || '\'-\''} does not contain all required keys."
        raise ConfigurationError, message
      end

      config.merge(environment: env)
    end

    def self.locate_config_file
      %w(.cloudstack .cloudstack-cli).each do |file|
        file = File.join(Dir.home, "#{file}.yml")
        return file if File.exists?(file)
      end
      nil
    end

  end
end
