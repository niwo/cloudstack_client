module CloudstackClient

  module ResourceLimit

    ##
    # List resource limits.

    def list_resource_limits(args = {})
      params = {
        'command' => 'listResourceLimits',
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

      if args[:project]
        project = get_project(args[:project])
        if !project
          msg = "Project '#{args[:project]}' is invalid"
          puts "Error: #{msg}"
          exit 1
        end
        params['projectid'] = project['id']
      elsif args[:project_id]
        params['projectid'] = args[:project_id]
      end

      params['type'] = args[:type] if args[:type]

      puts json = send_request(params)
      json['resource_limit'] || []
    end

  end

end
