require "test_helper"

describe CloudstackClient::Connection do
  let(:connection) do
    CloudstackClient::Connection.new(
      TestHelpers::TEST_URL,
      TestHelpers::TEST_KEY,
      TestHelpers::TEST_SECRET,
      quiet: true
    )
  end

  describe "input validation" do
    it "raises when the API URL is missing" do
      _(proc { CloudstackClient::Connection.new(nil, "k", "s") })
        .must_raise CloudstackClient::InputError
    end

    it "raises when the API key is missing" do
      _(proc { CloudstackClient::Connection.new("http://url", nil, "s") })
        .must_raise CloudstackClient::InputError
    end

    it "raises when the secret key is missing" do
      _(proc { CloudstackClient::Connection.new("http://url", "k", nil) })
        .must_raise CloudstackClient::InputError
    end

    it "raises when the async poll interval is below 1 second" do
      error = _(proc {
        CloudstackClient::Connection.new("http://url", "k", "s", async_poll_interval: 0.5)
      }).must_raise CloudstackClient::InputError
      _(error.message).must_match(/POLL INTERVAL/)
    end

    it "raises when the async timeout is below 60 seconds" do
      error = _(proc {
        CloudstackClient::Connection.new("http://url", "k", "s", async_timeout: 30)
      }).must_raise CloudstackClient::InputError
      _(error.message).must_match(/ASYNC TIMEOUT/)
    end

    it "raises when request retries is below 1" do
      error = _(proc {
        CloudstackClient::Connection.new("http://url", "k", "s", request_retries: 0)
      }).must_raise CloudstackClient::InputError
      _(error.message).must_match(/REQUEST RETRIES/)
    end

    it "applies the documented defaults" do
      _(connection.read_timeout).must_equal CloudstackClient::Connection::DEF_REQ_TIMEOUT
      _(connection.async_timeout).must_equal CloudstackClient::Connection::DEF_ASYNC_TIMEOUT
      _(connection.async_poll_interval).must_equal CloudstackClient::Connection::DEF_POLL_INTERVAL
      _(connection.request_retries).must_equal CloudstackClient::Connection::DEF_REQUEST_RETRIES
      _(connection.verify_ssl).must_equal true
      _(connection).wont_respond_to :secret_key=
    end

    it "allows SSL verification to be disabled explicitly" do
      configured = CloudstackClient::Connection.new(
        TestHelpers::TEST_URL,
        TestHelpers::TEST_KEY,
        TestHelpers::TEST_SECRET,
        verify_ssl: false,
        ca_file: "/tmp/cloudstack-ca.pem"
      )

      _(configured.verify_ssl).must_equal false
      _(configured.ca_file).must_equal "/tmp/cloudstack-ca.pem"
    end
  end

  describe "request signing" do
    # Golden value: HMAC-SHA1 of the downcased payload, Base64 encoded and then
    # URL escaped. Pinned so a change to the signing algorithm fails loudly.
    it "signs the downcased payload with HMAC-SHA1" do
      expected = CGI.escape(
        Base64.encode64(
          OpenSSL::HMAC.digest("sha1", TestHelpers::TEST_SECRET, "apikey=test-key&command=listzones")
        ).chomp
      )

      _(connection.send(:create_signature, "apiKey=test-key&command=listZones"))
        .must_equal expected
    end

    it "is case insensitive, because the payload is downcased before signing" do
      _(connection.send(:create_signature, "command=listZones"))
        .must_equal connection.send(:create_signature, "COMMAND=LISTZONES")
    end

    it "sends the signature and apiKey with the request" do
      stub_list("listZones", "zone", [{ "id" => "1" }])
      connection.send_request("command" => "listZones")

      params = last_request_params
      _(params["apiKey"].first).must_equal TestHelpers::TEST_KEY
      _(params["response"].first).must_equal "json"
      _(params["signature"].first).wont_be_nil
    end
  end

  describe "parameter serialization" do
    it "sorts parameters, since the signature depends on their order" do
      _(connection.send(:params_to_data, "z" => "1", "a" => "2", "m" => "3"))
        .must_equal "a=2&m=3&z=1"
    end

    it "serializes an Array of Hashes as an indexed map" do
      data = connection.send(:params_to_data,
        "tags" => [{ "key" => "role", "value" => "web" }])

      _(data).must_equal "tags[0].key=role&tags[0].value=web"
    end

    it "serializes a Hash as an indexed key/value map" do
      data = connection.send(:params_to_data, "details" => { "cpu" => "2" })

      _(data).must_equal "details[0].key=cpu&details[0].value=2"
    end

    it "escapes spaces as %20 rather than +" do
      _(connection.send(:escape, "my machine")).must_equal "my%20machine"
    end

    it "leaves asterisks unescaped" do
      _(connection.send(:escape, "*")).must_equal "*"
    end

    it "escapes reserved characters" do
      _(connection.send(:escape, "a&b=c")).must_equal "a%26b%3Dc"
    end
  end

  describe "response unwrapping" do
    it "returns the collection from a count plus collection response" do
      stub_list("listZones", "zone", [{ "id" => "1" }, { "id" => "2" }])

      _(connection.send_request("command" => "listZones"))
        .must_equal [{ "id" => "1" }, { "id" => "2" }]
    end

    it "keeps the count when include_count is requested" do
      stub_list("listZones", "zone", [{ "id" => "1" }])

      result = connection.send_request({ "command" => "listZones" }, include_count: true)
      _(result["count"]).must_equal 1
      _(result["zone"]).must_equal [{ "id" => "1" }]
    end

    it "returns an empty Array for a zero count response" do
      stub_command("listZones", { "listzonesresponse" => { "count" => 0 } })

      _(connection.send_request("command" => "listZones")).must_equal []
    end

    it "unwraps a single nested Hash" do
      stub_command("createUser", { "createuserresponse" => { "user" => { "id" => "42" } } })

      _(connection.send_request("command" => "createUser")).must_equal("id" => "42")
    end

    it "returns a scalar-valued body unchanged" do
      stub_command("someCommand", { "somecommandresponse" => { "jobid" => "job-9" } })

      _(connection.send_request("command" => "someCommand")).must_equal("jobid" => "job-9")
    end

    it "returns an empty body as an empty Array" do
      stub_command("listZones", { "listzonesresponse" => {} })

      _(connection.send_request("command" => "listZones")).must_equal []
    end
  end

  describe "symbolized keys" do
    let(:connection) do
      CloudstackClient::Connection.new(
        TestHelpers::TEST_URL, TestHelpers::TEST_KEY, TestHelpers::TEST_SECRET,
        quiet: true, symbolize_keys: true
      )
    end

    it "returns Symbol keys throughout the response" do
      stub_list("listZones", "zone", [{ "id" => "1", "name" => "zone1" }])

      _(connection.send_request("command" => "listZones"))
        .must_equal [{ id: "1", name: "zone1" }]
    end

    it "still strips the count key when it is symbolized" do
      stub_list("listZones", "zone", [{ "id" => "1" }])
      result = connection.send_request("command" => "listZones")

      _(result).must_equal [{ id: "1" }]
    end
  end

  describe "error handling" do
    it "raises ApiError with the errortext for a non-200 response" do
      stub_command("listZones",
        { "listzonesresponse" => { "errortext" => "Unable to execute" } },
        status: 431)

      error = _(proc { connection.send_request("command" => "listZones") })
        .must_raise CloudstackClient::ApiError
      _(error.message).must_match(/431/)
      _(error.message).must_match(/Unable to execute/)
    end

    it "raises ParseError when the body is not JSON" do
      stub_request(:get, ApiStubs::ANY_REQUEST).to_return(status: 200, body: "<html>oops</html>")

      error = _(proc { connection.send_request("command" => "listZones") })
        .must_raise CloudstackClient::ParseError
      _(error.message).must_match(/not readable/)
    end

    it "raises ConnectionError when the endpoint is unreachable" do
      stub_request(:get, ApiStubs::ANY_REQUEST).to_raise(Errno::ECONNREFUSED)

      error = _(proc { connection.send_request("command" => "listZones") })
        .must_raise CloudstackClient::ConnectionError
      _(error.message).must_match(/is not reachable/)
    end
  end

  describe "retries" do
    it "makes exactly one attempt with the default retry setting" do
      stub_request(:get, ApiStubs::ANY_REQUEST).to_raise(Errno::ECONNREFUSED)

      error = _(proc { connection.send_request("command" => "listZones") })
        .must_raise CloudstackClient::ConnectionError
      _(error.message).must_match(/after 1 attempt/)
      assert_requested(:get, ApiStubs::ANY_REQUEST, times: 1)
    end

    it "retries up to request_retries attempts before giving up" do
      connection = CloudstackClient::Connection.new(
        TestHelpers::TEST_URL, TestHelpers::TEST_KEY, TestHelpers::TEST_SECRET,
        quiet: true, request_retries: 3
      )
      stub_request(:get, ApiStubs::ANY_REQUEST).to_raise(Errno::ECONNREFUSED)

      error = connection.stub(:sleep, nil) do
        _(proc { connection.send_request("command" => "listZones") })
          .must_raise CloudstackClient::ConnectionError
      end

      _(error.message).must_match(/after 3 attempts/)
      assert_requested(:get, ApiStubs::ANY_REQUEST, times: 3)
    end

    it "returns the result when a retry succeeds" do
      connection = CloudstackClient::Connection.new(
        TestHelpers::TEST_URL, TestHelpers::TEST_KEY, TestHelpers::TEST_SECRET,
        quiet: true, request_retries: 3
      )
      stub_request(:get, ApiStubs::ANY_REQUEST)
        .to_raise(Errno::ECONNREFUSED)
        .then.to_return(
          status: 200,
          body: JSON.generate("listzonesresponse" => { "count" => 1, "zone" => [{ "id" => "1" }] })
        )

      result = connection.stub(:sleep, nil) do
        connection.send_request("command" => "listZones")
      end

      _(result).must_equal [{ "id" => "1" }]
    end
  end

  describe "asynchronous requests" do
    it "returns the jobresult once the job succeeds" do
      stub_async("deployVirtualMachine",
        polls: [job_success("virtualmachine" => { "id" => "vm-1" })])

      result = connection.stub(:sleep, nil) do
        connection.send_async_request("command" => "deployVirtualMachine")
      end

      _(result).must_equal("virtualmachine" => { "id" => "vm-1" })
    end

    it "polls until the job leaves the pending state" do
      stub_async("deployVirtualMachine",
        polls: [job_pending, job_pending, job_success("id" => "vm-1")])

      result = connection.stub(:sleep, nil) do
        connection.send_async_request("command" => "deployVirtualMachine")
      end

      _(result).must_equal("id" => "vm-1")
    end

    it "raises JobError when the job fails" do
      stub_async("deployVirtualMachine",
        polls: [job_failure("Insufficient capacity")])

      error = connection.stub(:sleep, nil) do
        _(proc { connection.send_async_request("command" => "deployVirtualMachine") })
          .must_raise CloudstackClient::JobError
      end

      _(error.message).must_match(/Insufficient capacity/)
      _(error.message).must_match(/530/)
    end

    it "raises JobError when a failed job has no error text" do
      stub_async(
        "deployVirtualMachine",
        polls: [{ "jobstatus" => 2, "jobresultcode" => 530 }]
      )

      error = connection.stub(:sleep, nil) do
        _(proc { connection.send_async_request("command" => "deployVirtualMachine") })
          .must_raise CloudstackClient::JobError
      end

      _(error.message).must_match(/Unknown error/)
    end

    it "raises TimeoutError when the job never completes" do
      stub_async("deployVirtualMachine", polls: [job_pending])

      error = connection.stub(:sleep, nil) do
        _(proc { connection.send_async_request("command" => "deployVirtualMachine") })
          .must_raise CloudstackClient::TimeoutError
      end

      _(error.message).must_match(/timed out/)
    end

    it "rejects per-request async options that are out of range" do
      _(proc {
        connection.send_async_request({ "command" => "x" }, async_timeout: 5)
      }).must_raise CloudstackClient::InputError
    end
  end

  describe "the host option" do
    it "sets the Host header when a host is given" do
      connection = CloudstackClient::Connection.new(
        TestHelpers::TEST_URL, TestHelpers::TEST_KEY, TestHelpers::TEST_SECRET,
        quiet: true, host: "cloudstack.internal"
      )
      stub_list("listZones", "zone", [{ "id" => "1" }])

      connection.send_request("command" => "listZones")

      assert_requested(:get, ApiStubs::ANY_REQUEST,
        headers: { "Host" => "cloudstack.internal" }, times: 1)
    end

    it "omits the Host header when no host is given" do
      stub_list("listZones", "zone", [{ "id" => "1" }])
      connection.send_request("command" => "listZones")

      signature = WebMock::RequestRegistry.instance.requested_signatures.hash.keys.last
      _(signature.headers.to_h.keys.map(&:downcase)).wont_include "host"
    end
  end
end
