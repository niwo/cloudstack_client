require "msgpack"
require "json"
require "ostruct"

module CloudstackClient
  class Api

    DEFAULT_API_VERSION = "4.2"

    attr_reader :commands

    def initialize(options = {})
      if options[:api_file]
        @api_file = options[:api_file]
        @api_version = File.basename(@api_file, ".msgpack")
      else
        @api_version = options[:api_version] || DEFAULT_API_VERSION
        @api_file = File.expand_path("../../../config/#{@api_version}.msgpack", __FILE__)
      end
      @commands = load_commands
    end

    def command_supports_param?(command, key)
      commands[command].params.detect { |p| p["name"] == key }
    end

    def required_params(command)
      commands[command].params.map do |param|
        param["name"] if param["required"] == true
      end.compact
    end

    def all_required_params?(command, args)
      required_params(command).all? {|k| args.key? k}
    end

    def normalize_key(key)
      key.to_s.gsub("_", "")
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
      @command_map
      commands = Hash.new
      api["api"].each do |command|
        commands[command["name"]] = OpenStruct.new command
      end
      commands
    end

  end
end
