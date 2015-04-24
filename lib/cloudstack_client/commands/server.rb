module CloudstackClient

  module Server

    ##
    # Finds the server with the specified name.

    def get_server(name, args = {})
      params = {
          'command' => 'listVirtualMachines',
          'listAll' => true,
          'name' => name
      }

      params['domainid'] = args[:domain_id] if args[:domain_id]
      if args[:account]
        account = list_accounts({name: args[:account]}).first
        unless account
          puts "Error: Account #{args[:account]} not found."
          exit 1
        end
        params['domainid'] = account["domainid"]
        params['account'] = args[:account]
      end

      if args[:project_id]
        params['projectid'] = args[:project_id]
      elsif args[:project]
        project = get_project(args[:project])
        if !project
          msg = "Project '#{args[:project]}' is invalid"
          puts "Error: #{msg}"
          exit 1
        end
        params['projectid'] = project['id']
      end

      json = send_request(params)
      machines = json['virtualmachine']

      if !machines || machines.empty? then
        return nil
      end

      machines.select {|m| m['name'] == name }.first
    end

    def get_server_state(id)
      params = {
          'command' => 'listVirtualMachines',
          'id' => id
      }
      json = send_request(params)
      machine_state = json['virtualmachine'][0]['state']

      if !machine_state || machine_state.empty?
        return nil
      end

      machine_state
    end

    def wait_for_server_state(id, state)
      while get_server_state(id) != state
        print '..'
        sleep 5
      end
      state
    end

    ##
    # Finds the public ip for a server

    def get_server_public_ip(server, cached_rules=nil)
      return nil unless server

      # find the public ip
      nic = get_server_default_nic(server) || {}
      if nic['type'] == 'Virtual'
        ssh_rule = get_ssh_port_forwarding_rule(server, cached_rules)
        ssh_rule ? ssh_rule['ipaddress'] : nil
      else
        nic['ipaddress']
      end
    end

    ##
    # Returns the fully qualified domain name for a server.

    def get_server_fqdn(server)
      return nil unless server

      nic = get_server_default_nic(server) || {}
      networks = list_networks(project_id: server['projectid']) || {}

      id = nic['networkid']
      network = networks.select { |net|
        net['id'] == id
      }.first
      return nil unless network

      "#{server['name']}.#{network['networkdomain']}"
    end

    def get_server_default_nic(server)
      server['nic'].each do |nic|
        return nic if nic['isdefault']
      end
    end

    ##
    # Lists servers.

    def list_servers(args = {})
      params = {
        'command' => 'listVirtualMachines',
        'listAll' => true
      }
      params.merge!(args[:custom]) if args[:custom]

      params['state'] = args[:state] if args[:state]
      params['state'] = args[:status] if args[:status]
      params['groupid'] = args[:group_id] if args[:group_id]


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

      json = send_request(params)
      json['virtualmachine'] || []
    end

    ##
    # Deploys a new server using the specified parameters.

    def create_server(args = {})
      params = {'command' => 'deployVirtualMachine'}
      params['keypair'] = args[:keypair] if args[:keypair]
      params['size'] = args[:disk_size] if args[:disk_size]
      params['group'] = args[:group] if args[:group]
      params['displayname'] = args[:displayname] if args[:displayname]

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
      params['name'] = args[:name] if args[:name]

      if args[:name]
        server = get_server(args[:name], project_id: params['projectid'])
        if server
          puts "Error: Server '#{args[:name]}' already exists."
          exit 1
        end
      end

      networks = []
      if args[:networks]
        args[:networks].each do |name|
          network = get_network(name, params['projectid'])
          if !network
            puts "Error: Network '#{name}' not found"
            exit 1
          end
          networks << network
        end
      end
      if networks.empty?
        unless default_network = get_default_network
          puts "Error: No default network found"
          exit 1
        end
        networks << default_network
      end
      network_ids = networks.map { |network|
        network['id']
      }
      params['networkids'] = network_ids.join(',')

      service = get_service_offering(args[:offering])
      if !service
        puts "Error: Service offering '#{args[:offering]}' is invalid"
        exit 1
      end
      params['serviceOfferingId'] = service['id']

      if args[:template]
        template = get_template(args[:template])
        if !template
          puts "Error: Template '#{args[:template]}' is invalid"
          exit 1
        end
      end

      if args[:disk_offering]
        disk_offering = get_disk_offering(args[:disk_offering])
        unless disk_offering
          msg = "Disk offering '#{args[:disk_offering]}' is invalid"
          puts "Error: #{msg}"
          exit 1
        end
        params['diskofferingid'] = disk_offering['id']
      end

      if args[:iso]
        iso = get_iso(args[:iso])
        unless iso
          puts "Error: Iso '#{args[:iso]}' is invalid"
          exit 1
        end
        unless disk_offering
          puts "Error: a disk offering is required when using iso"
          exit 1
        end
        params['hypervisor'] = (args[:hypervisor] || 'vmware')
      end

      if !template && !iso
        puts "Error: Iso or Template is required"
        exit 1
      end
      params['templateId'] = template ? template['id'] : iso['id']

      zone = args[:zone] ? get_zone(args[:zone]) : get_default_zone
      if !zone
        msg = args[:zone] ? "Zone '#{args[:zone]}' is invalid" : "No default zone found"
        puts "Error: #{msg}"
        exit 1
      end
      params['zoneid'] = zone['id']

      args[:sync] ? send_request(params) : send_async_request(params)['virtualmachine']
    end

    ##
    # Stops the server with the specified name.
    #

    def stop_server(name, args = {})
      server = get_server(name, args)
      if !server || !server['id']
        puts "Error: Virtual machine '#{name}' does not exist"
        exit 1
      end

      params = {
          'command' => 'stopVirtualMachine',
          'id' => server['id']
      }
      params['forced'] = true if args[:forced]
      args[:sync] ? send_request(params) : send_async_request(params)['virtualmachine']
    end

    ##
    # Start the server with the specified name.
    #

    def start_server(name, args = {})
      server = get_server(name, args)
      if !server || !server['id']
        puts "Error: Virtual machine '#{name}' does not exist"
        exit 1
      end

      params = {
          'command' => 'startVirtualMachine',
          'id' => server['id']
      }
      args[:sync] ? send_request(params) : send_async_request(params)['virtualmachine']
    end

    ##
    # Reboot the server with the specified name.
    #

    def reboot_server(name, args = {})
      server = get_server(name, args)
      if !server || !server['id']
        puts "Error: Virtual machine '#{name}' does not exist"
        exit 1
      end

      params = {
          'command' => 'rebootVirtualMachine',
          'id' => server['id']
      }
      args[:sync] ? send_request(params) : send_async_request(params)['virtualmachine']
    end

    ##
    # Destroy the server with the specified name.
    #

    def destroy_server(id, args = {})
      params = {
          'command' => 'destroyVirtualMachine',
          'id' => id
      }
      params['expunge'] = true if args[:expunge]
      args[:sync] ? send_request(params) : send_async_request(params)['virtualmachine']
    end

  end

 end
