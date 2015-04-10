require 'cloudstack_client/client'
require 'thor'
require 'yaml'
require 'ripl'

module CloudstackClient
  class Cli < Thor
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

    desc "version", "Print cloudstack_client version number"
    def version
      say "cloudstack_client version #{CloudstackClient::VERSION}"
    end
    map %w(-v --version) => :version

    desc "list_apis", "list api commands using the Cloudstack API Discovery service"
    option :format, default: 'json',
      enum: %w(json yaml), desc: "output format"
    option :pretty_print, default: true, type: :boolean,
      desc: "pretty print json output"
    option :remove_response, default: true, type: :boolean,
      desc: "remove response sections"
    option :remove_description, default: true, type: :boolean,
      desc: "remove description sections"
    def list_apis
      data = client.send_request('command' => 'listApis')
      data["api"].each do |command|
        command.delete("response") if options[:remove_response]
        if options[:remove_description]
          command.delete("description")
          command["params"].each {|param| param.delete("description")}
        end
      end
      output = if options[:format] == "json"
        options[:pretty_print] ? JSON.pretty_generate(data) : data.to_json
      else
        data.to_yaml
      end
      puts output
    end

    desc "console", "Cloudstack Client interactive shell"
    def console
      puts "cloudstack_client version #{CloudstackClient::VERSION}"
      puts '  try: list_virtual_machines state: "Started"'
      ARGV.clear
      env = options[:env] ? options[:env] : load_configuration.last
      Ripl.config[:prompt] = "#{env} >> "
      Ripl.start binding: client.instance_eval('binding')
    end

    no_commands do
      def client(opts = {})
        @config ||= load_configuration.first
        @client ||= CloudstackClient::Client.new(
          @config[:url],
          @config[:api_key],
          @config[:secret_key]
        )
      end

      def load_configuration(config_file = options[:config_file], env = options[:env])
        unless File.exists?(config_file)
          say "Configuration file #{config_file} not found.", :red
          say "Please run \'cloudstack-cli environment add\' to create one."
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
        return config, env
      end

    end # no_commands

	end # class
end # module
