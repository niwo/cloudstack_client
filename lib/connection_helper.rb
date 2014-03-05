module CloudstackClient
  class ConnectionHelper
    def self.load_configuration(config_file)
      begin
        return YAML::load(IO.read(config_file))
      rescue => e
        puts "Unable to load '#{config_file}' : #{e}"
        exit
      end
    end
  end
end