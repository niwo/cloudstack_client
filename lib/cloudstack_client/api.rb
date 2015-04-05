require "json"
#require "ostruct"

module CloudstackClient
  module Api

    def self.underscore(name)
      name.gsub(/::/, '/').
        gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
        gsub(/([a-z\d])([A-Z])/,'\1_\2').
        tr("-", "_").
        downcase
    end


    VERSION = "4.2"
    api_file = "./config/#{VERSION}.json"

    begin
      api = JSON.parse(IO.read api_file)
    rescue => e
      puts "Error: Unable to load '#{api_file}' : #{e}"
      exit
    end

    api["api"].each do |command|
      method_name = underscore(command['name']).to_sym

      define_method(method_name) do |args = {}|
        params = {"command" => command['name']}

        args.each do |arg|
          params[arg.gsub("_", "")] = arg
        end

        response = send_request(params)
        return [] unless response.respond_to?(:keys)

        items = if response.size == 2 && response.key?('count')
          response.reject { |key, _| key == 'count' }.values.first
        elsif response.size == 1 && response.values.first.respond_to?(:keys)
          response.values.first
        end
        #items.map {|item| OpenStruct.new item }
      end

    end

  end
end
