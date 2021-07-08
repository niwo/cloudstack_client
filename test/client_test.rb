require "test_helper"

describe CloudstackClient::Client do
  before do
    @client = CloudstackClient::Client.new(
      "https://cloudstack.api/client/api",
      "test-key",
      "test-secret"
    )
  end

  describe "when the client is instantiated" do
    it "must respond_to 'list_virtual_machines'" do
      _(@client.respond_to?(:list_virtual_machines)).must_equal true
    end

    it "must respond_to 'deploy_virtual_machine'" do
      _(@client.respond_to?(:deploy_virtual_machine)).must_equal true
    end

    it "must respond_to 'create_user'" do
      _(@client.respond_to?(:create_user)).must_equal true
    end

    it "must not be in debug mode" do
      _(@client.debug).must_equal false
    end
  end
end
