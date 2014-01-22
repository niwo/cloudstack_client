module CloudstackClient

	module AffinityGroup

		##
    # List Affinity Groups.

    def list_affinity_groups(args = {})
      params = {
        'command' => 'listAffinityGroups',
      }

      if args[:account]
        account = list_accounts({name: args[:account]}).first
        unless account
          puts "Error: Account #{args[:account]} not found."
          exit 1
        end
        params['domainid'] = account["domainid"]
        params['account'] = args[:account]
      end

      if args['listall']
        params['listall'] = true
        params['isrecursive'] = true
      end

      params['name'] = args['name'] if args['name']
      params['type'] = args['type'] if args['type']
      params['virtualmachineid'] = args['virtualmachine_id'] if args['virtualmachine_id']
      params['keyword'] = args['keyword'] if args['keyword']

      json = send_request(params)
      json['affinitygroup'] || []
    end

	end

end