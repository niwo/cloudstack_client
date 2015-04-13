require "json"
require "ostruct"

module CloudstackClient
  class Api

    DEFAULT_API_VERSION = "4.2"

    def initialize(options = {})
      unless options[:api_file]
        @api_version = options[:api_version] || DEFAULT_API_VERSION
        @api_file = File.expand_path("../../../config/#{@api_version}.json", __FILE__)
      else
        @api_file = options[:api_file]
        @api_version = File.basename(@api_file, ".json")
      end
    end

    def commands
      begin
        api = JSON.parse(IO.read @api_file)
      rescue => e
        puts "Error: Unable to load '#{@api_file}' : #{e}"
        exit
      end
      api["api"].map {|command| OpenStruct.new command }
    end

  end
end
