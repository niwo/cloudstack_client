require "msgpack"
require "json"
require "ostruct"

module CloudstackClient
  class Api

    DEFAULT_API_VERSION = "4.2"

    def initialize(options = {})
      if options[:api_file]
        @api_file = options[:api_file]
        @api_version = File.basename(@api_file, ".msgpack")
      else
        @api_version = options[:api_version] || DEFAULT_API_VERSION
        @api_file = File.expand_path("../../../config/#{@api_version}.msgpack", __FILE__)
      end
    end

    def commands
      begin
        api = MessagePack.unpack(IO.read @api_file)
      rescue => e
        raise "Error: Unable to read file '#{@api_file}' : #{e.message}"
      end
      api["api"].map {|command| OpenStruct.new command }
    end

  end
end
