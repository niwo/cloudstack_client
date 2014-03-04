module CloudstackClient

  module Configuration

    ##
    # List configuration.

    def list_configurations(args = {})
      params = {
        'command' => 'listConfigurations',
      }

      if args[:zone]
        zone = get_zone(args[:zone])
        unless zone 
          puts "Error: Zone #{args[:zone]} not found"
          exit 1
        end
        params['zoneid'] = zone['id']  
      end

      if args[:account]
        account = list_accounts({name: args[:account]}).first
        unless account
          puts "Error: Account #{args[:account]} not found."
          exit 1
        end
        params['domainid'] = account["domainid"]
        params['account'] = args[:account]
      end

      params['name'] = args[:name] if args[:name]
      params['keyword'] = args[:keyword] if args[:keyword]
      params['category'] = args[:category] if args[:category]

      json = send_request(params)
      json['configuration'] || []
    end

  end

end