# cloudstack_client

[![Gem Version](https://badge.fury.io/rb/cloudstack_client.png)](http://badge.fury.io/rb/cloudstack_client)
 [![Build Status](https://travis-ci.com/niwo/cloudstack_client.svg?branch=master)](https://travis-ci.com/niwo/cloudstack_client)

A CloudStack API client written in Ruby.

## Installation

Install the cloudstack_client gem:

```bash
$ gem install cloudstack_client
```

## Features

- Access to the whole CloudStack-API from Ruby
- Interactive console for playing with the CloudStack API: ```cloudstack_client console```
- Dynamically builds API methods based on the listApis function of CloudStack
- Command names are converted to match Ruby naming conventions (i.e. ListVirtualMachines becomes list_virtual_machines)
- Accepts Ruby Hash arguments passed to commands as options (i.e. list_all: true becomes listall=true)
- Assure all required arguments are passed
- Removes unsupported arguments and arguments with nil values from commands

## Usage

### Basic usage

```ruby
require "cloudstack_client"

cs = CloudstackClient::Client.new(
  "https://cloudstack.local/client/api",
  "API_KEY",
  "SECRET_KEY"
)

cs.list_virtual_machines(state: "running").each do |vm|
  puts vm["name"]
end
```

### Advanced Options

Load API definition file from an alternative path and set the version:

```ruby
cs = CloudstackClient::Client.new(
  "https://cloudstack.local/client/api",
  "API_KEY",
  "SECRET_KEY",
  {
    api_path: "~/cloudstack",
    api_version: "4.15"
  }
)
```

...or load the API definition directly from a file:

```ruby
cs = CloudstackClient::Client.new(
  "https://cloudstack.local/client/api",
  "API_KEY",
  "API_SECRET",
  { api_file: "~/cloudstack/4.15.json.gz" }
)
```

### Pagination and Response Options

When working with paginated responses, you can include the total count in the API response:

```ruby
# Get paginated results with count information
vms = cs.list_virtual_machines({ page: 1, pagesize: 10 }, { include_count: true })
total_count = vms[:count]
items = vms[:virtualmachine]

# Default behavior (without count)
vms = cs.list_virtual_machines(page: 1, pagesize: 10)
# Returns just the items array
```

### Using the configuration module

The configuration module of CloudstackClient makes it easy to load CloudStack API settings from configuration files.

#### Example

```ruby
require "cloudstack_client"
require "cloudstack_client/configuration"

# looks for ~/.cloudstack.yml per default
config = CloudstackClient::Configuration.load
cs = CloudstackClient::Client.new(config[:url], config[:api_key], config[:secret_key])
```

#### Configuration files

Configuration files support multiple environments (i.e. `~/.cloudstack.yml`):

```yaml
# default environment
:default: production

# production environment
production:
  :url: "https://my-cloudstack-server/client/api/"
  :api_key: "cloudstack-api-key"
  :secret_key: "cloudstack-api-secret"

# test environment
test:
  :url: "http://my-cloudstack-testserver/client/api/"
  :api_key: "cloudstack-api-key"
  :secret_key: "cloudstack-api-secret"
```

### Configuration options
You can pass `options` as 4th argument in `CloudstackClient::Client.new`. All its keys are optional.

```ruby
options = {
  symbolize_keys: true, # pass symbolize_names: true in JSON#parse for Cloudstack responses, default: false
  host: 'localhost', # custom host header to be used in Net::Http. May be useful when Cloudstack is set up locally via docker (i.e. Cloudstack-simulator), default: parsed from config[:url] via Net::Http
  read_timeout: 10 # timeout in seconds of a connection to the Cloudstack, default: 60
}
cs = CloudstackClient::Client.new(config[:url], config[:api_key], config[:secret_key], options)
```

### Interactive Console

cloudstack_client comes with an interactive console.

#### Example

```bash
$ cloudstack_client console -e prod
prod >> list_virtual_machines
```

## Development

### Generate or update API definitions

New API definitions can be generated using the `list_apis` command.

#### Example

```bash
# running against a CloudStack 4.15 API endpoint:
$ cloudstack_client list_apis > data/4.15.json
$ gzip data/4.15.json
```

## References

- [Apache CloudStack API documentation](http://cloudstack.apache.org/api/apidocs-4.15/)

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

Released under the MIT License. See the [LICENSE](https://raw.github.com/niwo/cloudstack_client/master/LICENSE.txt) file for further details.
