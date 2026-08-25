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

  describe "when the configuration cannot be loaded" do
    it "must raise when the file does not exist" do
      error = _(proc {
        CloudstackClient::Configuration.load(config_file: "/nonexistent/cloudstack.yml")
      }).must_raise CloudstackClient::ConfigurationError

      _(error.message).must_match(/not found/)
    end

    it "must raise when the file is not valid YAML" do
      error = _(proc {
        CloudstackClient::Configuration.load(
          config_file: "#{File.expand_path File.dirname(__FILE__)}/data/cloudstack-malformed.yml"
        )
      }).must_raise CloudstackClient::ConfigurationError

      _(error.message).must_match(/Can't load configuration/)
    end

    it "must reject unsafe YAML objects" do
      error = _(proc {
        CloudstackClient::Configuration.load(
          config_file: "#{File.expand_path File.dirname(__FILE__)}/data/cloudstack-unsafe.yml"
        )
      }).must_raise CloudstackClient::ConfigurationError

      _(error.message).must_match(/Can't load configuration/)
    end

    it "must include the backtrace in debug mode" do
      error = _(proc {
        CloudstackClient::Configuration.load(
          config_file: "#{File.expand_path File.dirname(__FILE__)}/data/cloudstack-malformed.yml",
          debug: true
        )
      }).must_raise CloudstackClient::ConfigurationError

      _(error.message).must_match(/Backtrace/)
    end

    it "must raise when the requested environment is absent" do
      error = _(proc {
        CloudstackClient::Configuration.load(
          config_file: "#{File.expand_path File.dirname(__FILE__)}/data/cloudstack-1.yml",
          env: "nope"
        )
      }).must_raise CloudstackClient::ConfigurationError

      _(error.message).must_match(/Can't find environment nope/)
    end

    it "must raise when required keys are missing" do
      error = _(proc {
        CloudstackClient::Configuration.load(
          config_file: "#{File.expand_path File.dirname(__FILE__)}/data/cloudstack-incomplete.yml"
        )
      }).must_raise CloudstackClient::ConfigurationError

      _(error.message).must_match(/does not contain all required keys/)
    end

    it "must raise when a required value is empty" do
      error = _(proc {
        CloudstackClient::Configuration.load(
          config_file: "#{File.expand_path File.dirname(__FILE__)}/data/cloudstack-empty.yml"
        )
      }).must_raise CloudstackClient::ConfigurationError

      _(error.message).must_match(/does not contain all required keys/)
    end
  end

  describe "when the configuration is valid" do
    it "must return the url and secret key alongside the environment" do
      config = CloudstackClient::Configuration.load(
        config_file: "#{File.expand_path File.dirname(__FILE__)}/data/cloudstack-1.yml"
      )

      _(config[:url]).must_equal "https://cloud.swisstxt.ch/client/api/"
      _(config[:environment]).must_equal "test1"
      _(config[:secret_key]).wont_be_nil
    end
  end

end
