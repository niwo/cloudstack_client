require "test_helper"

describe CloudstackClient::Api do
  before do
    @api = CloudstackClient::Api.new
  end

  describe "when the API is initialized" do
    it "has to find the default version in available versions" do
      CloudstackClient::Api.versions.include?(
        CloudstackClient::Api::DEFAULT_API_VERSION
      ).must_equal true
    end

    it "must raise exception for unavailable version" do
      proc { CloudstackClient::Api.new(api_version: "0.0") }.must_raise RuntimeError
    end

    it "must set correct version of fake api file" do
      CloudstackClient::Api.new(
        api_file: "#{File.expand_path File.dirname(__FILE__)}/data/0.42.json.gz"
      ).api_version.must_equal "0.42"
    end

    it "must set correct api file of fake api when loaded with api_version option" do
      CloudstackClient::Api.new(
        api_path: "#{File.expand_path File.dirname(__FILE__)}/data/",
      ).api_file.must_equal "#{File.expand_path File.dirname(__FILE__)}/data/0.42.json.gz"
    end
  end

  describe "when commands are accessed" do
    it "must return a Hash" do
      @api.commands.class.must_equal Hash
    end

    it "must have a key named 'listDomains'" do
      @api.commands.has_key?('listDomains').must_equal true
    end

    it "the 'listDomains' element must  contain the correct 'name' value" do
      @api.commands['listDomains']['name'].must_equal "listDomains"
    end

    it "the 'listDomains' element must  contain 'params'" do
      @api.commands['listDomains'].has_key?('params').must_equal true
    end
  end

  describe "when asked about supported commands" do
    it "must respond positively for 'listVirtualMachines'" do
      @api.command_supported?('listVirtualMachines').must_equal true
    end

    it "must respond positively for 'list_virtual_machines'" do
      @api.command_supported?('list_virtual_machines').must_equal true
    end

    it "must respond positively for 'createUser'" do
      @api.command_supported?('createUser').must_equal true
    end

    it "must respond positively for 'create_user'" do
      @api.command_supported?('create_user').must_equal true
    end

    it "must respond netagively for 'listClowns'" do
      @api.command_supported?('listClowns').must_equal false
    end

    it "must respond netagively for 'list_clowns'" do
      @api.command_supported?('list_clowns').must_equal false
    end
  end

  describe "when asked about supported params" do
    it "must respond positively for 'listVirtualMachines' and param 'name'" do
      @api.command_supports_param?('listVirtualMachines', 'name').must_equal true
    end

    it "must respond netagively for 'listVirtualMachines' and param 'hotdog'" do
      @api.command_supports_param?('listVirtualMachines', 'hotdog').must_equal false
    end
  end

  describe "when asked about required params" do
    it "must respond with correct Array for 'createUser'" do
      params = %w(account email firstname lastname password username)
      @api.required_params('createUser').sort.must_equal params.sort
    end
  end

  describe "when asked about all required params" do
    it "must respond positively for 'createUser' and params 'account, email, firtsname, lastname, password, username'" do
      params = {
        "account"   => "Master",
        "email"     => "me@me.com",
        "firstname" => "Me",
        "lastname"  => "Me",
        "password"  => "secret",
        "username"  => "meme",
        "domainid"  => "1"
      }
      @api.all_required_params?('createUser', params).must_equal true
    end

    it "must respond netagively for 'createUser' and params 'username'" do
      @api.all_required_params?('createUser', { "username" => "meme" }).must_equal false
    end
  end

end
