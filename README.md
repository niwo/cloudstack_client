# cloudstack_client

[![Gem Version](https://badge.fury.io/rb/cloudstack_client.png)](http://badge.fury.io/rb/cloudstack_client)
https://travis-ci.org/niwo/cloudstack_client.svg?branch=master

A CloudStack API client written in Ruby.

## Installation

Install the cloudstack_client gem:

```bash
$ gem install cloudstack_client
```

## Usage

```ruby
require "cloudstack_client"

cs = CloudstackClient::Client.new(
  "https://cloudstack.local/client/api",
  "API_KEY",
  "API_SECRET"
)

cs.list_virtual_machines(state: "running").each do |server|
  puts server["name"]
end
```

## Features

  - Dynamically builds API methods based on the lisApis function of CloudStack
  - Command names are converted to match Ruby naming conventions (i.e. ListVirtualMachines becomes list_virtual_machines)
  - Accepts Ruby style args passed to commands (i.e. list_all: true becomes listall=true)
  - makes sure all required arguments are passed
  - Removes unsupported arguments and arguments with nil values from commands

## Development

### Generate new API configs

New API configs can be genearted using the list_apis command.

*Example:*

```bash
# running against an CloudStack 4.5 API endpoint:
$ cloudstack_client list_apis > config/4.5.msgpack
```

### Interactive Console

cloudstack_client comes with an interactive shell to test the client.

*Example:*

```bash
$ cloudstack_client console -e prod
prod >> list_virtual_machines
```

## References
-  [Apache CloudStack API documentation](http://cloudstack.apache.org/docs/api/)

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

Copyright (c) 2014-2015, Nik Wolfgramm

Released under the MIT License. See the [LICENSE](https://raw.github.com/niwo/cloudstack_client/master/LICENSE.txt) file for further details.
