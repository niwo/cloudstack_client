module CloudstackClient

  module SystemVm

    ##
    # List system virtual machines.

    def list_system_vms(args = {})
      params = {
        'command' => 'listSystemVms'
      }

      if args[:zone]
        zone = get_zone(args[:zone])
        unless zone
          puts "Error: zone #{args[:project]} not found."
          exit 1
        end
        params['zoneid'] = zone['id']
      end

      params['state'] = args[:state] if args[:state]
      params['podid'] = args[:podid] if args[:podid]

      json = send_request(params)
      json['system_vm'] || []
    end

  end

end
