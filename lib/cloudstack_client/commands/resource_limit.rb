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
        params['domainid'] = account['domainid']
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

      json = send_request(params)
      json['resourcelimit'] || []
    end

    ##
    # Recalculate and update resource count for an account or domain.

    def update_resource_count(args = {})
      params = {
        'command' => 'updateResourceCount',
      }

      if args[:account]
        account = list_accounts({name: args[:account]}).first
        unless account
          puts "Error: Account #{args[:account]} not found."
          exit 1
        end
        params['domainid'] = account['domainid']
        params['account'] = args[:account]
      end

      if args[:project]
        project = get_project(args[:project])
        if !project
          msg = "Project '#{args[:project]}' is invalid"
          puts "Error: #{msg}"
          exit 1
        end
        params['domainid'] = project['domainid']
        params['projectid'] = project['id']
      elsif args[:project_id]
        params['projectid'] = args[:project_id]
      end

      params['resourcetype'] = args[:resource_type] if args[:resource_type]
      params['domainid'] = args[:domain_id] if args[:domain_id]

      json = send_request(params)
      json['resourcecount'] || []
    end

    ##
    # Updates resource limits for an account or domain.

    def update_resource_limit(args = {})
      params = {
        'command' => 'updateResourceLimit',
      }

      if args[:resource_type]
        params['resourcetype'] = args[:resource_type]
      else
        puts "Error: Resource Type must be specified."
        exit 1
      end

      if args[:account]
        account = list_accounts({name: args[:account]}).first
        unless account
          puts "Error: Account #{args[:account]} not found."
          exit 1
        end
        params['domainid'] = account['domainid']
        params['account'] = args[:account]
      end

      if args[:project]
        project = get_project(args[:project])
        if !project
          msg = "Project '#{args[:project]}' is invalid"
          puts "Error: #{msg}"
          exit 1
        end
        params['domainid'] = project['domainid']
        params['projectid'] = project['id']
      elsif args[:project_id]
        params['projectid'] = args[:project_id]
      end

      params['domainid'] = args[:domain_id] if args[:domain_id]
      params['max'] = args[:max] if args[:max]

      json = send_request(params)
      json['resourcelimit'] || []
    end

  end

end
