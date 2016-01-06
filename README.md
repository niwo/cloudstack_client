# cloudstack_client

[![Gem Version](https://badge.fury.io/rb/cloudstack_client.png)](http://badge.fury.io/rb/cloudstack_client)
 [![Build Status](https://travis-ci.org/niwo/cloudstack_client.svg?branch=master)](https://travis-ci.org/niwo/cloudstack_client)

A CloudStack API client written in Ruby.

## Installation

Install the cloudstack_client gem:

```bash
$ gem install cloudstack_client
```

## Features
  - Interactive console for playing with the CloudStack API: ```cloudstack_client console```
  - Dynamically builds API methods based on the listApis function of CloudStack
  - Command names are converted to match Ruby naming conventions (i.e. ListVirtualMachines becomes list_virtual_machines)
  - Accepts Ruby Hash arguments passed to commands as options (i.e. list_all: true becomes listall=true)
  - Makes sure all required arguments are passed
  - Removes unsupported arguments and arguments with nil values from commands

## Usage

### Basic usage

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

### Initialize with options

*Load API definition file from a alternative path and set the version:*

```ruby
cs = CloudstackClient::Client.new(
  "https://cloudstack.local/client/api",
  "API_KEY",
  "API_SECRET",
  {
    api_path: "~/cloudstack",
    api_version: "4.6"
  }
)
```

*..or load the API definition directly from a file:*

```ruby
cs = CloudstackClient::Client.new(
  "https://cloudstack.local/client/api",
  "API_KEY",
  "API_SECRET",
  { api_file: "~/cloudstack/4.6.json.gz" }
)
```

### Interactive Console

cloudstack_client comes with an interactive shell to test the client.

*Example:*

```bash
$ cloudstack_client console -e prod
prod >> list_virtual_machines
```

## Development

### Generate/Update API versions

New API configs can be generated using the list_apis command.

*Example:*

```bash
# running against an CloudStack 4.5 API endpoint:
$ cloudstack_client list_apis > data/4.5.json
$ gzip data/4.5.json
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

Copyright (c) 2014-2016, Nik Wolfgramm

Released under the MIT License. See the [LICENSE](https://raw.github.com/niwo/cloudstack_client/master/LICENSE.txt) file for further details.
