require "cloudstack_client/client"
require "yaml"

begin
  require "thor"
  require "ripl"
rescue LoadError => e
  missing_gem = if e.message =~ /thor/
    "thor"
  elsif e.message =~ /ripl/
    "ripl"
  else
    raise
  end
  puts "Please install the #{missing_gem} gem first ('gem install #{missing_gem}')."
  exit 1
end

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
    option :format, default: 'msgpack',
      enum: %w(msgpack json yaml), desc: "output format"
    option :pretty_print, default: true, type: :boolean,
      desc: "pretty print json output"
    option :remove_response, default: true, type: :boolean,
      desc: "remove response sections"
    option :remove_description, default: true, type: :boolean,
      desc: "remove description sections"
    def list_apis
      apis = client(no_api_methods: true).send_request('command' => 'listApis')
      apis.each do |command|
        command.delete("response") if options[:remove_response]
        if options[:remove_description]
          command.delete("description")
          command["params"].each {|param| param.delete("description")}
        end
      end

      print case options[:format]
      when "json"
        options[:pretty_print] ? JSON.pretty_generate(apis) : apis.to_json
      when "yaml"
        apis.to_yaml
      else
        apis.to_msgpack
      end
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
          @config[:secret_key],
          opts
        )
      end

      def load_configuration(config_file = options[:config_file], env = options[:env])
        unless File.exists?(config_file)
          say "Configuration file #{config_file} not found.", :red
          say "Please run 'cloudstack-cli environment add' to create one."
          exit 1
        end

        begin
          config = YAML::load(IO.read(config_file))
        rescue
          say "Can't load configuration from file #{config_file}.", :red
          exit 1
        end

        if env ||= config[:default]
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
