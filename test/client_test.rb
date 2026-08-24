require "test_helper"

describe CloudstackClient::Client do
  let(:client) do
    CloudstackClient::Client.new(
      TestHelpers::TEST_URL, TestHelpers::TEST_KEY, TestHelpers::TEST_SECRET, quiet: true
    )
  end

  describe "when the client is instantiated" do
    it "exposes the loaded API definition" do
      _(client.api).must_be_kind_of CloudstackClient::Api
      _(client.api.api_version).must_equal CloudstackClient::Api::DEFAULT_API_VERSION
    end

    it "is not in debug mode by default" do
      _(client.debug).must_equal false
    end

    it "defines no API methods when no_api_methods is set" do
      bare = bare_client
      _(bare.respond_to?(:list_virtual_machines)).must_equal false
      _(bare.api).must_be_nil
    end
  end

  describe "generated command methods" do
    it "sends the CloudStack command name for the underscored method" do
      stub_list("listVirtualMachines", "virtualmachine", [{ "id" => "vm-1" }])

      client.list_virtual_machines

      _(last_request_params["command"].first).must_equal "listVirtualMachines"
    end

    it "returns the unwrapped collection" do
      stub_list("listVirtualMachines", "virtualmachine",
        [{ "id" => "vm-1" }, { "id" => "vm-2" }])

      _(client.list_virtual_machines).must_equal [{ "id" => "vm-1" }, { "id" => "vm-2" }]
    end

    it "strips underscores from argument names" do
      stub_list("listVirtualMachines", "virtualmachine", [])

      client.list_virtual_machines(list_all: true)

      _(last_request_params["listall"].first).must_equal "true"
    end

    it "passes through arguments that need no translation" do
      stub_list("listVirtualMachines", "virtualmachine", [])

      client.list_virtual_machines(state: "running")

      _(last_request_params["state"].first).must_equal "running"
    end

    it "drops arguments the command does not support" do
      stub_list("listVirtualMachines", "virtualmachine", [])

      client.list_virtual_machines(state: "running", hotdog: "mustard")

      params = last_request_params
      _(params).must_include "state"
      _(params).wont_include "hotdog"
    end

    it "drops arguments with a nil value" do
      stub_list("listVirtualMachines", "virtualmachine", [])

      client.list_virtual_machines(state: nil, name: "web01")

      params = last_request_params
      _(params).must_include "name"
      _(params).wont_include "state"
    end

    it "accepts String keys as well as Symbol keys" do
      stub_list("listVirtualMachines", "virtualmachine", [])

      client.list_virtual_machines("state" => "running")

      _(last_request_params["state"].first).must_equal "running"
    end
  end

  describe "required parameter validation" do
    it "raises ParameterError when a required parameter is missing" do
      error = _(proc { client.deploy_virtual_machine(zoneid: "1") })
        .must_raise CloudstackClient::ParameterError

      _(error.message).must_match(/deployVirtualMachine requires/)
      _(error.message).must_match(/serviceofferingid/)
      _(error.message).must_match(/templateid/)
    end

    it "does not issue a request when validation fails" do
      _(proc { client.create_user(username: "meme") })
        .must_raise CloudstackClient::ParameterError

      assert_not_requested(:get, ApiStubs::ANY_REQUEST)
    end

    it "proceeds when every required parameter is present" do
      stub_command("createUser", { "createuserresponse" => { "user" => { "id" => "u-1" } } })

      result = client.create_user(
        account: "Master", email: "me@me.com", firstname: "Me",
        lastname: "Me", password: "secret", username: "meme"
      )

      _(result).must_equal("id" => "u-1")
    end
  end

  describe "synchronous and asynchronous dispatch" do
    it "sends a synchronous command directly" do
      stub_list("listVirtualMachines", "virtualmachine", [])

      client.list_virtual_machines

      assert_not_requested(:get, ApiStubs::ANY_REQUEST,
        query: hash_including("command" => "queryAsyncJobResult"))
    end

    it "polls for an asynchronous command" do
      stub_async("deployVirtualMachine",
        polls: [job_success("id" => "vm-1")])

      result = client.stub(:sleep, nil) do
        client.deploy_virtual_machine(
          zoneid: "1", serviceofferingid: "2", templateid: "3"
        )
      end

      _(result).must_equal("id" => "vm-1")
      assert_requested(:get, ApiStubs::ANY_REQUEST,
        query: hash_including("command" => "queryAsyncJobResult"))
    end

    it "forces a synchronous request when the sync option is given" do
      stub_command("deployVirtualMachine",
        { "deployvirtualmachineresponse" => { "jobid" => "job-1" } })

      result = client.deploy_virtual_machine(
        { zoneid: "1", serviceofferingid: "2", templateid: "3" }, { sync: true }
      )

      _(result).must_equal("jobid" => "job-1")
      assert_not_requested(:get, ApiStubs::ANY_REQUEST,
        query: hash_including("command" => "queryAsyncJobResult"))
    end
  end
end
