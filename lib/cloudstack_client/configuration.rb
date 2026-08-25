module CloudstackClient
  require "yaml"

  module Configuration

    def self.load(configuration)
      file = configuration[:config_file] || Configuration.locate_config_file
      unless File.exist?(file)
        raise ConfigurationError, "Configuration file '#{file}' not found."
      end

      begin
        config = YAML.safe_load(IO.read(file), permitted_classes: [Symbol])
      rescue => e
        message = "Can't load configuration from file '#{file}'."
        if configuration[:debug]
          message += "\nMessage: #{e.message}"
          message += "\nBacktrace:\n\t#{e.backtrace.join("\n\t")}"
        end
        raise ConfigurationError, message
      end

      unless config.is_a?(Hash)
        raise ConfigurationError, "Configuration file '#{file}' must contain a hash."
      end

      if env = configuration[:env] || config[:default]
        unless config = config[env]
          raise ConfigurationError, "Can't find environment #{env}."
        end
      end

      unless config.is_a?(Hash)
        raise ConfigurationError, "Environment #{env} must contain a hash."
      end

      required_keys = %i[url api_key secret_key]
      missing_keys = required_keys.reject do |key|
        config.key?(key) && !config[key].to_s.strip.empty?
      end
      unless missing_keys.empty?
        message = "The environment #{env || '\'-\''} does not contain all required keys."
        raise ConfigurationError, message
      end

      config.merge(environment: env)
    end

    def self.locate_config_file
      %w(.cloudstack .cloudstack-cli).each do |file|
        file = File.join(Dir.home, "#{file}.yml")
        return file if File.exist?(file)
      end
      nil
    end

  end
end
