require "cloudstack_client"

require "minitest/spec"
require "minitest/autorun"
# Minitest 6 extracted Object#stub into the minitest-mock gem.
require "minitest/mock"
require "minitest/reporters"

require "webmock/minitest"

# No test may reach the network. An accidental live request should fail loudly
# rather than turn into a slow or flaky test.
WebMock.disable_net_connect!(allow_localhost: false)

Minitest::Reporters.use!(
  ENV["CI"] ? Minitest::Reporters::ProgressReporter.new : Minitest::Reporters::SpecReporter.new
)

require_relative "support/api_stubs"

module TestHelpers
  TEST_URL    = "https://cloudstack.test/client/api".freeze
  TEST_KEY    = "test-key".freeze
  TEST_SECRET = "test-secret".freeze

  def fixture_path(*parts)
    File.join(File.expand_path("data", __dir__), *parts)
  end

  # A client with no dynamically defined API methods: useful when the test
  # targets Connection behaviour rather than the generated command methods.
  def bare_client(options = {})
    CloudstackClient::Client.new(
      TEST_URL, TEST_KEY, TEST_SECRET, { no_api_methods: true }.merge(options)
    )
  end
end

class Minitest::Spec
  include TestHelpers
  include ApiStubs
end
