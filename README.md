# cloudstack_client

[![Gem Version](https://img.shields.io/gem/v/cloudstack_client.svg)](https://rubygems.org/gems/cloudstack_client)
[![CI](https://github.com/niwo/cloudstack_client/actions/workflows/ci.yml/badge.svg)](https://github.com/niwo/cloudstack_client/actions/workflows/ci.yml)

A CloudStack API client written in Ruby.

## Version 2.0.0

Version 2.0.0 requires Ruby 3.0 or newer. It also fixes request dispatch when
no custom host is configured and improves support for CloudStack commands with
acronyms, such as `create_ssh_key_pair`.

## Installation

Install the cloudstack_client gem:

```bash
gem install cloudstack_client
```

## Features

- Access to the whole CloudStack-API from Ruby
- Interactive console for playing with the CloudStack API:
  `cloudstack_client console`
- Dynamically builds API methods based on the listApis function of CloudStack
- Command names are converted to match Ruby naming conventions (i.e.
  ListVirtualMachines becomes list_virtual_machines)
- Accepts Ruby Hash arguments passed to commands as options (i.e. `list_all: true`
  becomes `listall=true`)
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

When working with paginated responses, you can include the total count in the
API response:

```ruby
# Get paginated results with count information
vms = cs.list_virtual_machines(
  { page: 1, pagesize: 10 },
  { include_count: true }
)
total_count = vms[:count]
items = vms[:virtualmachine]

# Default behavior (without count)
vms = cs.list_virtual_machines(page: 1, pagesize: 10)
# Returns just the items array
```

### Using the configuration module

The configuration module of CloudstackClient makes it easy to load CloudStack
API settings from configuration files.

#### Configuration Example

```ruby
require "cloudstack_client"
require "cloudstack_client/configuration"

# looks for ~/.cloudstack.yml per default
config = CloudstackClient::Configuration.load
cs = CloudstackClient::Client.new(
  config[:url],
  config[:api_key],
  config[:secret_key]
)
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

You can pass `options` as 4th argument in `CloudstackClient::Client.new`.
All its keys are optional.

```ruby
options = {
  # Pass symbolize_names: true in JSON#parse for CloudStack responses.
  # Default: false.
  symbolize_keys: true,
  # Custom host header for Net::HTTP. Useful with CloudStack-simulator.
  # Default: parsed from config[:url] via Net::HTTP.
  host: 'localhost',
  # Timeout in seconds for a connection to CloudStack. Default: 60.
  read_timeout: 10,
  # HTTP request attempts before raising ConnectionError. Default: 1.
  # Uses incremental back-off between attempts.
  request_retries: 3
}
cs = CloudstackClient::Client.new(
  config[:url],
  config[:api_key],
  config[:secret_key],
  options
)
```

For a single call you can override defaults on the **second** hash (client
options), without changing the client instance:

```ruby
cs.deploy_virtual_machine(
  { zoneid: "...", serviceofferingid: "...", templateid: "..." },
  async_timeout: 600,
  async_poll_interval: 5
)
```

### Interactive Console

cloudstack_client comes with an interactive console.

#### Console Example

```bash
cloudstack_client console -e prod
prod >> list_virtual_machines
```

## Development

### Running the tests

```bash
bundle install
bundle exec rake          # tests and RuboCop
bundle exec rake test     # tests only
bundle exec rake rubocop  # RuboCop only
bundle exec rake benchmark
```

Tests use [Minitest](https://github.com/minitest/minitest) in spec style and
[WebMock](https://github.com/bblimke/webmock). Outbound network access is
disabled in the test suite, so any request that is not stubbed fails the test
rather than reaching a real endpoint. Helpers for stubbing CloudStack responses
live in `test/support/api_stubs.rb`.

`Gemfile.lock` is deliberately not checked in, so each supported Ruby version
resolves its own compatible dependency set.

### Generate or update API definitions

New API definitions can be generated using the `list_apis` command.

#### API Definition Example

```bash
# running against a CloudStack 4.15 API endpoint:
cloudstack_client list_apis > data/4.15.json
gzip data/4.15.json
```

### GitHub Actions

This repository includes GitHub Actions workflows for:

- Running tests and gem build against every supported Ruby version, plus a
  RuboCop lint job, on every push and pull request (`CI`)
- Publishing the gem to RubyGems when a GitHub Release is published (`Release`)

Dependency and GitHub Actions updates are proposed weekly by Dependabot.

To enable publishing, add this repository secret:

- `RUBYGEMS_AUTH_TOKEN`: your RubyGems API key with push permissions

The release workflow checks that `CloudstackClient::VERSION` is greater than
the latest version on RubyGems before building, then uses the `rubygems`
environment to publish.

## References

- [Apache CloudStack API documentation](http://cloudstack.apache.org/api/apidocs-4.15/)

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

Released under the MIT License. See the
[LICENSE](https://raw.github.com/niwo/cloudstack_client/master/LICENSE.txt)
file for further details.
