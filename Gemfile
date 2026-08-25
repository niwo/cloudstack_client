source 'https://rubygems.org'

# Specify your gem's dependencies in cloudstack-client.gemspec
gemspec

# Minitest 6 extracted Minitest::Mock and Object#stub into their own gem, but
# that gem requires Ruby >= 3.1. On Ruby 3.0 Bundler resolves Minitest 5, which
# still ships minitest/mock itself, so the require works either way.
gem 'minitest-mock', require: false if RUBY_VERSION >= '3.1'
