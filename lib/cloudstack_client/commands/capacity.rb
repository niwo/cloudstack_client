module CloudstackClient

	module Capacity

		##
    # List capacity.

    def list_capacity(args = {})
      params = {
        'command' => 'listCapacity',
      }

      if args[:zone]
        zone = get_zone(args[:zone])
        unless zone 
          puts "Error: Zone #{args[:zone]} not found"
          exit 1
        end
        params['zoneid'] = zone['id']  
      end

      params['type'] = args[:type] if args[:type]

      json = send_request(params)
      json['capacity'] || []
    end

	end

end