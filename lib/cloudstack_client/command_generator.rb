require 'cloudstack_client/client'
require 'connection_helper'
require 'thor'
require 'yaml'

module CloudstackClient
  class CommandGenerator < Thor
    include Thor::Actions

    class_option :config_file,
      default: File.join(Dir.home, '.cloudstack-cli.yml'),
      aliases: '-c',
      desc: 'location of your cloudstack-cli configuration file'

    class_option :env,
      aliases: '-e',
      desc: 'environment to use'

    class_option :debug,
      desc: 'enable debug output',
      type: :boolean

    desc "generate", "generate api commands using the Cloudstack API Discovery service"
    def generate
      say json = client.send_request('command' => 'listApis')
      commands = ['apis'] || []
      commands.each do |command|
        say command['name']
      end
    end

    no_commands do  
      def client(opts = {})
        @config ||= load_configuration
        @client ||= CloudstackClient::Connection.new(
          @config[:url],
          @config[:api_key],
          @config[:secret_key],
          {no_commands: true}
        )
      end

      def load_configuration(config_file = options[:config_file], env = options[:env])
        unless File.exists?(config_file)
          say "Configuration file #{config_file} not found.", :red
          say "Please run \'cs environment add\' to create one."
          exit 1
        end

        begin
          config = YAML::load(IO.read(config_file))
        rescue
          say "Can't load configuration from file #{config_file}.", :red
          exit 1
        end
        
        env ||= config[:default]
        if env
          unless config = config[env]
            say "Can't find environment #{env}.", :red
            exit 1
          end
        end

        unless config.key?(:url) && config.key?(:api_key) && config.key?(:secret_key)
          say "The environment #{env || '\'-\''} contains no valid data.", :red
          exit 1
        end
        config
      end

    end # no_commands

	end # class
end # module