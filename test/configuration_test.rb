require "test_helper"
require "cloudstack_client/configuration"

describe CloudstackClient::Configuration do

  describe "when the configuration is loaded without env" do
    it "must use the default env'" do
      _(CloudstackClient::Configuration.load({
        config_file: "#{File.expand_path File.dirname(__FILE__)}/data/cloudstack-1.yml",
        debug: true
      })[:environment]).must_equal "test1"
    end
  end

  describe "when an alternative env is in the options" do
    it "must use the alternative env'" do
      _(CloudstackClient::Configuration.load({
        config_file: "#{File.expand_path File.dirname(__FILE__)}/data/cloudstack-1.yml",
        env: "test2",
        debug: true
      })[:environment]).must_equal "test2"
    end
  end

  describe "when only one env is present" do
    it "must use the one existing configuration'" do
      _(CloudstackClient::Configuration.load({
        config_file: "#{File.expand_path File.dirname(__FILE__)}/data/cloudstack-2.yml",
        debug: true
      })[:api_key]).must_equal "test-test-test-test-test-test-test-test-test-test-test-test-test-test-test-test-test"
    end
  end

end
