module CloudstackClient

	module Volume

		##
    # Lists all volumes.

    def list_volumes(args = {})
      params = {
          'command' => 'listVolumes',
          'listall' => true,
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
        if account = list_accounts(name: args[:account]).first
          params['domainid'] = account["domainid"]
          params['account'] = args[:account]
        end
      end

      params['projectid'] = args[:project_id] if args[:project_id]
      params['type'] = args[:type] if args[:type]
      params['keyword'] = args[:keyword] if args[:keyword]
      params['name'] = args[:name] if args[:name]
  
      json = send_request(params)
      json['volume'] || []
    end

	end

end