module CloudstackClient

	module Region

		##
    # List regions.

    def list_regions(args = {})
      params = {
        'command' => 'listRegions',
      }

      json = send_request(params)
      json['region'] || []
    end

	end

end