require "test_helper"
require "cloudstack_client/configuration"

describe CloudstackClient::Configuration do

  before do
    @config1 = CloudstackClient::Configuration.load({
      config_file: "#{File.expand_path File.dirname(__FILE__)}/data/cloudstack-1.yml",
      debug: true
    })
    @config2 = CloudstackClient::Configuration.load({
      config_file: "#{File.expand_path File.dirname(__FILE__)}/data/cloudstack-2.yml",
      debug: true
    })
  end

  describe "when the configuration is loaded without env" do
    it "must use the default env'" do
      @config1[:environment].must_equal "test1"
    end
  end

  describe "when only one env is present" do
    it "must use the one existing configuration'" do
      @config2[:api_key].must_equal "test-test-test-test-test-test-test-test-test-test-test-test-test-test-test-test-test"
    end
  end

end
