module CloudstackClient
  module Utils

    def camel_case_to_underscore(camel_case)
      camel_case.gsub(/::/, '/').
        gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
        gsub(/([a-z\d])([A-Z])/,'\1_\2').
        tr("-", "_").downcase
    end

    def print_debug_output(output, seperator = '-' * 80)
      puts
      puts seperator
      puts output
      puts seperator
      puts
    end
    
  end
end
