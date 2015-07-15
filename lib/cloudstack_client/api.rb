require "msgpack"

module CloudstackClient
  class Api

    DEFAULT_API_VERSION = "4.5"

    attr_reader :commands
    attr_reader :api_version

    def self.versions
      Dir["#{self.config_path}/*.msgpack"].map do |path|
        File.basename(path, ".msgpack")
      end
    end

    def self.config_path
      File.expand_path("../../../config/", __FILE__)
    end

    def initialize(options = {})
      if options[:api_file]
        @api_file = options[:api_file]
        @api_version = File.basename(@api_file, ".msgpack")
      else
        @api_version = options[:api_version] || DEFAULT_API_VERSION
        unless Api.versions.include? @api_version
          raise "API definition not found for #{@api_version}"
        end
        @api_file = File.join(Api.config_path, "#{@api_version}.msgpack")
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
      begin
        api = MessagePack.unpack(IO.read @api_file)
      rescue => e
        raise "Error: Unable to read file '#{@api_file}' : #{e.message}"
      end
      commands = Hash.new
      api.each { |command| commands[command["name"]] = command }
      commands
    end

  end
end
