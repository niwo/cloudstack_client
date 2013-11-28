module CloudstackClient

	module Pod

		##
    # Lists pods.

    def list_pods(args = {})
      params = {
        'command' => 'listPods',
      }
      params['podid'] = args[:pod_id] if args[:pod_id]

      json = send_request(params)
      json['pod'] || []
    end

	end

end