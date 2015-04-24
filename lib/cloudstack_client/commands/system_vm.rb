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
      params['systemvmtype'] = args[:type] if args[:type]
      params['storageid'] = args[:storage_id] if args[:storage_id]

      json = send_request(params)
      json['systemvm'] || []
    end

    ##
    # Stop system VM.
    #

    def stop_system_vm(id, args = {})
      params = {
        'command' => 'stopSystemVm',
        'id' => id
      }
      params['forced'] = true if args[:forced]
      args[:sync] ? send_request(params) : send_async_request(params)['systemvm']
    end

    ##
    # Start system VM.
    #

    def start_system_vm(id, args = {})
      params = {
        'command' => 'startSystemVm',
        'id' => id
      }
      args[:sync] ? send_request(params) : send_async_request(params)['systemvm']
    end

    ##
    # Reboot sytem VM.
    #

    def reboot_system_vm(id, args = {})
      params = {
        'command' => 'rebootSystemVm',
        'id' => id
      }
      args[:sync] ? send_request(params) : send_async_request(params)['systemvm']
    end

    ##
    # Destroy sytem VM.
    #

    def destroy_system_vm(id, args = {})
      params = {
          'command' => 'destroySystemVm',
          'id' => id
      }
      args[:sync] ? send_request(params) : send_async_request(params)['systemvm']
    end

  end # module

end
