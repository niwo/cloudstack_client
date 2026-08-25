require "zlib"
require "json"
require "cloudstack_client/error"
require "cloudstack_client/utils"

module CloudstackClient
  class Api
    include Utils

    DEFAULT_API_VERSION = "4.5"
    API_PATH = File.expand_path("../../../data/", __FILE__)

    attr_reader :commands
    attr_reader :api_version, :api_file, :api_path

    def self.versions(api_path = API_PATH)
      Dir[api_path + "/*.json.gz"].map do |path|
        File.basename(path, ".json.gz")
      end
    end

    def initialize(options = {})
      set_api_path(options)
      set_api_version_and_file(options)
      load_commands
    end

    def command_supported?(command)
      !find_command(command).nil?
    end

    def command_supports_param?(command, key)
      command = find_command(command)
      return false if command.nil?

      command["params"].any? { |param| param["name"] == key.to_s }
    end

    # Resolves a command given either its CloudStack name ("createSSHKeyPair")
    # or its underscored Ruby name ("create_ssh_key_pair").
    #
    # underscore_to_camel_case cannot be relied on here: converting to
    # underscores loses acronym casing, so "create_ssh_key_pair" converts back
    # to "createSshKeyPair", which is not a CloudStack command. Underscored
    # names are resolved through an index built in the lossy direction instead.
    #
    # The index is built on first use: most lookups arrive as CloudStack names
    # and hit @commands directly, so instantiating an Api should not pay for it.
    def find_command(command)
      command = command.to_s
      @commands[command] || underscored_commands[command]
    end

    def required_params(command)
      self.params(command).map do |param|
        param["name"] if param["required"] == true
      end.compact
    end

    def params(command)
      @commands[command]["params"]
    end

    def all_required_params?(command, args)
      required_params(command).all? { |k| args.key? k }
    end

    def missing_params_msg(command)
      "#{command} requires the following parameter" +
      "#{ 's' if required_params(command).size > 1 }: " +
      required_params(command).join(", ")
    end

    private

    def set_api_version_and_file(options)
      if options[:api_file]
        @api_file = options[:api_file]
        @api_version = File.basename(@api_file, ".json.gz")
      else
        set_api_version(options)
        @api_file = File.join(@api_path, "#{@api_version}.json.gz")
      end
    end

    def set_api_path(options)
      @api_path = if options[:api_path]
        File.expand_path(options[:api_path])
      else
        API_PATH
      end
    end

    def set_api_version(options)
      @api_version = options[:api_version] || DEFAULT_API_VERSION
      unless Api.versions(@api_path).include? @api_version
        if options[:api_version]
          raise "API definition not found for version '#{@api_version}' in api_path '#{@api_path}'"
        elsif Api.versions(@api_path).size < 1
          raise "no API file available in api_path '#{@api_path}'"
        else
          @api_version = Api.versions(@api_path).last
        end
      end
      @api_version
    end

    def underscored_commands
      @underscored_commands ||= @commands.each_with_object({}) do |(name, command), index|
        index[camel_case_to_underscore(name)] = command
      end
    end

    def load_commands
      @commands = {}
      @underscored_commands = nil
      Zlib::GzipReader.open(@api_file) do |gz|
        JSON.parse(gz.read)
      end.each {|cmd| @commands[cmd["name"]] = cmd }
    rescue Zlib::Error, JSON::ParserError, SystemCallError, EOFError => e
      raise ApiDefinitionError,
            "Unable to read API definition '#{@api_file}': #{e.message}"
    end

  end
end
