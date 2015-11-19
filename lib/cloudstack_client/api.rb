require "zlib"

module CloudstackClient
  class Api

    DEFAULT_API_VERSION = "4.5"
    DATA_PATH = File.expand_path("../../../data/", __FILE__)

    attr_reader :commands
    attr_reader :api_version, :api_file, :data_path

    def self.versions(data_path = DATA_PATH)
      Dir[data_path + "/*.json.gz"].map do |path|
        File.basename(path, ".json.gz")
      end
    end

    def initialize(options = {})
      @data_path = options[:data_path] || DATA_PATH
      set_api_version_and_file(options)
      load_commands
    end

    def command_supported?(command)
      @commands.has_key? command
    end

    def command_supports_param?(command, key)
      if @commands[command]["params"].detect { |p| p["name"] == key }
        true
      else
        false
      end
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
        @api_file = File.join(@data_path, "#{@api_version}.json.gz")
      end
    end

    def set_api_version(options)
      @api_version = options[:api_version] || DEFAULT_API_VERSION
      unless Api.versions(@data_path).include? @api_version
        raise "API definition not found for #{@api_version}" if options[:api_version]
        if Api.versions(@data_path).size < 1
          raise "no API file available in data_path '#{@data_path}'"
        else
          @api_version = Api.versions(@data_path).last
        end
      end
      @api_version
    end

    def load_commands
      @commands = {}
      Zlib::GzipReader.open(@api_file) do |gz|
        JSON.parse(gz.read)
      end.each {|cmd| @commands[cmd["name"]] = cmd }
    rescue => e
      raise "Error: Unable to read file '#{@api_file}': #{e.message}"
    end

  end
end
