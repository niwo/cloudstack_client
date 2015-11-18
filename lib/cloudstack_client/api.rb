require "zlib"

module CloudstackClient
  class Api

    DEFAULT_API_VERSION = "4.5"

    attr_reader :commands
    attr_reader :api_version

    def self.versions
      Dir["#{self.config_path}/*.json.gz"].map do |path|
        File.basename(path, ".json.gz")
      end
    end

    def self.config_path
      File.expand_path("../../../data/", __FILE__)
    end

    def initialize(options = {})
      if options[:api_file]
        @api_file = options[:api_file]
        @api_version = File.basename(@api_file, ".json")
      else
        @api_version = options[:api_version] || DEFAULT_API_VERSION
        unless Api.versions.include? @api_version
          raise "API definition not found for #{@api_version}"
        end
        @api_file = File.join(Api.config_path, "#{@api_version}.json.gz")
      end
      @commands = load_commands
    end

    def command_supported?(command)
      @commands.has_key? command
    end

    def command_supports_param?(command, key)
      @commands[command]["params"].detect { |p| p["name"] == key } ? true : false
    end

    def required_params(command)
      @commands[command]["params"].map do |param|
        param["name"] if param["required"] == true
      end.compact
    end

    def all_required_params?(command, args)
      required_params(command).all? { |k| args.key? k }
    end

    def missing_params_msg(command)
      requ = required_params(command)
      "#{command} requires the following parameter#{ 's' if requ.size > 1}: #{requ.join(', ')}"
    end

    private

    def load_commands
      commands = {}
      begin
        api = Zlib::GzipReader.open(@api_file) do |gz|
          JSON.parse(gz.read)
        end
      rescue => e
        raise "Error: Unable to read file '#{@api_file}' : #{e.message}"
      end
      api.each do |command|
        commands[command["name"]] = command
      end
      commands
    end

  end
end
