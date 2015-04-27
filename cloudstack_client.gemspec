# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cloudstack_client/version'

Gem::Specification.new do |gem|
  gem.name          = "cloudstack_client"
  gem.version       = CloudstackClient::VERSION
  gem.authors       = ["Nik Wolfgramm"]
  gem.email         = ["nik.wolfgramm@gmail.com"]
  gem.description   = %q{CloudStack API client written in Ruby}
  gem.summary       = %q{CloudStack API client written in Ruby}
  gem.homepage      = "https://github.com/niwo/cloudstack_client"
  gem.license       = 'MIT'

  gem.required_ruby_version = '>= 1.9.3'
  gem.files         = `git ls-files`.split($/)
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  gem.rdoc_options  = %w[--line-numbers --inline-source]

  gem.add_dependency('msgpack')

  gem.add_development_dependency('rdoc')
  gem.add_development_dependency('rake', '~> 10.0', '>= 10.0.4')
  gem.add_development_dependency('thor')
  gem.add_development_dependency('ripl')
end
