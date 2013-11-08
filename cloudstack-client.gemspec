# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cloudstack-client/version'

Gem::Specification.new do |gem|
  gem.name          = "cloudstack-client"
  gem.version       = CloudstackClient::VERSION
  gem.authors       = ["Nik Wolfgramm"]
  gem.email         = ["nik.wolfgramm@gmail.com"]
  gem.description   = %q{A ruby CloudStack API client}
  gem.summary       = %q{A ruby CloudStack API client}
  gem.homepage      = "https://bitbucket.org/swisstxt/cloudstack-client"
  gem.license       = 'MIT'

  gem.required_ruby_version = '>= 1.9.3'
  gem.files         = `git ls-files`.split($/)
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  gem.rdoc_options  = %w[--line-numbers --inline-source]

  gem.add_development_dependency('rdoc')
  gem.add_development_dependency('rake', '~> 10.0.4')
end