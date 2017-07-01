require "cloudstack_client/client"
require "cloudstack_client/configuration"
require "yaml"
require "json"

begin
  require "thor"
  require "ripl"
rescue LoadError => e
  %w(thor ripl).each do |gem|
    if e.message =~ /#{gem}/
      puts "Please install the #{gem} gem first ('gem install #{gem}')."
      exit 1
    end
  end
  raise e.message
end

module CloudstackClient
  class Cli < Thor
    include Thor::Actions

    class_option :config_file,
      default: CloudstackClient::Configuration.locate_config_file,
      aliases: '-c',
      desc: 'location of your cloudstack-cli configuration file'

    class_option :env,
      aliases: '-e',
      desc: 'environment to use'

    class_option :debug,
      desc: 'enable debug output',
      type: :boolean

    # rescue error globally
    def self.start(given_args=ARGV, config={})
      super
    rescue => e
      error_class = e.class.name.split('::')
      if error_class.size == 2 && error_class.first == "CloudstackClient"
        puts "\e[31mERROR\e[0m: #{error_class.last} - #{e.message}"
        puts e.backtrace if ARGV.include? "--debug"
      else
        raise
      end
    end

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
      apis = client(no_api_methods: true).send_request('command' => 'listApis')
      apis.each do |command|
        command.delete("response") if options[:remove_response]
        if options[:remove_description]
          command.delete("description")
          command["params"].each {|param| param.delete("description")}
        end
      end

      print case options[:format]
      when "yaml"
        apis.to_yaml
      else
        options[:pretty_print] ? JSON.pretty_generate(apis) : JSON.generate(apis)
      end
    end

    desc "console", "Cloudstack Client interactive shell"
    option :api_version,
      desc: 'API version to use',
      default: CloudstackClient::Api::DEFAULT_API_VERSION
    option :api_file,
      desc: 'specify a custom API definition file'
    option :pretty_print,
      desc: 'pretty client output',
      type: :boolean,
      default: true
    def console
      cs_client = client(options)

      print "cloudstack_client version #{CloudstackClient::VERSION}"
      puts " (CloudStack API version #{cs_client.api.api_version})"
      puts "  try: list_virtual_machines state: \"running\""

      ARGV.clear
      Ripl.config[:prompt] = "#{@config[:environment]} >> "
      Ripl.start binding: cs_client.instance_eval{ binding }
    end

    no_commands do
      def client(opts = {})
        @config ||= CloudstackClient::Configuration.load(options)
        @client ||= CloudstackClient::Client.new(
          @config[:url],
          @config[:api_key],
          @config[:secret_key],
          opts
        )
      end
    end # no_commands

	end # class
end # module
