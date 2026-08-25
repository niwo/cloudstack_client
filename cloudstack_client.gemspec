# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cloudstack_client/version'

Gem::Specification.new do |gem|
  gem.name          = "cloudstack_client"
  gem.version       = CloudstackClient::VERSION
  gem.authors       = ["Nik Wolfgramm"]
  gem.email         = ["nik.wolfgramm@gmail.com"]
  gem.description   = %q{A Ruby client for the Apache CloudStack API that builds its
                          methods dynamically from the CloudStack API definition,
                          including an interactive console.}.gsub(/\s+/, ' ')
  gem.summary       = %q{CloudStack API client written in Ruby}
  gem.homepage      = "https://github.com/niwo/cloudstack_client"
  gem.license       = 'MIT'

  gem.required_ruby_version = '>= 3.0'
  gem.files         = `git ls-files`.split($/)
  gem.executables   = %w(cloudstack_client)
  gem.require_paths = ["lib"]
  gem.rdoc_options  = %w[--line-numbers --inline-source]

  gem.metadata = {
    "homepage_uri"      => gem.homepage,
    "bug_tracker_uri"   => "#{gem.homepage}/issues",
    "changelog_uri"     => "#{gem.homepage}/releases",
    "rubygems_mfa_required" => "true"
  }

  # base64 stopped being a default gem in Ruby 3.4, so `require "base64"`
  # in connection.rb fails under Bundler unless it is declared here.
  gem.add_dependency('base64', '>= 0.1')

  gem.add_development_dependency('rake', '~> 13.0')
  gem.add_development_dependency('thor', '~> 1.1')
  gem.add_development_dependency('ripl', '~> 0.7')
  # Allow minitest 6 on Ruby >= 3.2 while staying installable on Ruby 3.0/3.1.
  gem.add_development_dependency('minitest', '>= 5.14', '< 7')
  gem.add_development_dependency('minitest-reporters', '~> 1.8')
  gem.add_development_dependency('webmock', '~> 3.26')
  gem.add_development_dependency('benchmark', '>= 0.3')
  gem.add_development_dependency('rubocop', '~> 1.90')
  gem.add_development_dependency('rubocop-minitest', '~> 0.40')
  gem.add_development_dependency('rubocop-rake', '~> 0.7')
end
