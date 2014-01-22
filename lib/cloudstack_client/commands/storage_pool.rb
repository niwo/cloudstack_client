module CloudstackClient

	module StoragePool

		##
    # Lists all storage pools.

    def list_storage_pools(args = {})
      params = {
          'command' => 'listStoragePools',
      }

      if args[:zone]
        zone = get_zone(args[:zone])
        unless zone 
          puts "Error: Zone #{args[:zone]} not found"
          exit 1
        end
        params['zoneid'] = zone['id']  
      end

      params['keyword'] = args[:keyword] if args[:keyword]
      params['name'] = args[:name] if args[:name]
  
      json = send_request(params)
      json['storagepool'] || []
    end

	end

end