module CloudstackClient

	module Capacity

		##
    # List capacity.

    def list_capacity(args = {})
      params = {
        'command' => 'listCapacity',
      }
      params['zoneid'] = args[:zone_id] if args[:zone_id]
      params['type'] = args[:type] if args[:type]

      json = send_request(params)
      json['capacity'] || []
    end

	end

end