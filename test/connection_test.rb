require "test_helper"

# A stand-in for Net::HTTP that records what it was configured with and
# returns a canned response, so the connection can be exercised without a
# network or an HTTP stubbing library.
class FakeHttp
  attr_reader :requests
  attr_accessor :use_ssl, :verify_mode, :read_timeout

  def initialize(body:, code: "200")
    @body = body
    @code = code
    @requests = []
  end

  def request(req)
    @requests << req
    response_class = @code == "200" ? Net::HTTPOK : Net::HTTPBadRequest
    response = response_class.new("1.1", @code, "")
    response.instance_variable_set(:@body, @body)
    response.instance_variable_set(:@read, true)
    response
  end
end

describe CloudstackClient::Connection do
  API_URL = "https://cloudstack.api/client/api".freeze

  ZONES_BODY = JSON.dump(
    "listzonesresponse" => { "count" => 1, "zone" => [{ "id" => "z1" }] }
  ).freeze

  # Swaps Net::HTTP.new for one returning +fake+, for the block's duration.
  def with_fake_http(fake)
    original = Net::HTTP.method(:new)
    Net::HTTP.define_singleton_method(:new) { |*_args| fake }
    yield fake
  ensure
    Net::HTTP.define_singleton_method(:new, original)
  end

  def connection(options = {})
    CloudstackClient::Connection.new(
      API_URL, "test-key", "test-secret", { quiet: true }.merge(options)
    )
  end

  describe "when sending a request without ActiveSupport loaded" do
    it "must not raise when no host option is given" do
      with_fake_http(FakeHttp.new(body: ZONES_BODY)) do
        _(connection.send_request("command" => "listZones")).must_equal [{ "id" => "z1" }]
      end
    end

    it "must not set a Host header when no host option is given" do
      with_fake_http(FakeHttp.new(body: ZONES_BODY)) do |fake|
        connection.send_request("command" => "listZones")
        _(fake.requests.first["Host"]).must_be_nil
      end
    end

    it "must not set a Host header when the host option is empty" do
      with_fake_http(FakeHttp.new(body: ZONES_BODY)) do |fake|
        connection(host: "").send_request("command" => "listZones")
        _(fake.requests.first["Host"]).must_be_nil
      end
    end

    it "must set a Host header when the host option is given" do
      with_fake_http(FakeHttp.new(body: ZONES_BODY)) do |fake|
        connection(host: "cloudstack.internal").send_request("command" => "listZones")
        _(fake.requests.first["Host"]).must_equal "cloudstack.internal"
      end
    end
  end

  describe "when connecting over https" do
    it "must verify the peer certificate by default" do
      with_fake_http(FakeHttp.new(body: ZONES_BODY)) do |fake|
        connection.send_request("command" => "listZones")
        _(fake.verify_mode).must_equal OpenSSL::SSL::VERIFY_PEER
      end
    end

    it "must not verify the peer certificate when ssl_verify is false" do
      with_fake_http(FakeHttp.new(body: ZONES_BODY)) do |fake|
        connection(ssl_verify: false).send_request("command" => "listZones")
        _(fake.verify_mode).must_equal OpenSSL::SSL::VERIFY_NONE
      end
    end
  end

  describe "when signing a request" do
    # Signatures are what CloudStack authenticates on, so these guard the
    # base64 encoding against regressions.
    it "must produce the expected signature for a known request" do
      data = "apikey=test-key&command=listzones"
      expected = CGI.escape(
        [OpenSSL::HMAC.digest("sha1", "test-secret", data)].pack("m0")
      )
      _(connection.send(:create_signature, data)).must_equal expected
    end

    it "must not contain newlines" do
      # A long parameter string makes the digest encoding wrap if the
      # encoder inserts line breaks.
      data = "command=listzones&" + (1..50).map { |i| "param#{i}=value#{i}" }.join("&")
      _(connection.send(:create_signature, data)).wont_match(/%0A|\n/)
    end
  end
end
