# cloudstack_client

[![Gem Version](https://badge.fury.io/rb/cloudstack_client.png)](http://badge.fury.io/rb/cloudstack_client)

A CloudStack API client written in Ruby.

## Installation

Install the cloudstack_client gem:

    $ gem install cloudstack_client
    
## Usage

```ruby
require "cloudstack_client"
    
cs = CloudstackClient::Connection.new(
  'https://cloudstack.url/client/api',
  'API_KEY',
  'API_SECRET'
)
     
cs.list_servers(state: 'running').each do |server|
  puts server['name']
end
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

Copyright (c) 2014, Nik Wolfgramm

Released under the MIT License. See the [LICENSE](https://raw.github.com/niwo/cloudstack_client/master/LICENSE.txt) file for further details.
