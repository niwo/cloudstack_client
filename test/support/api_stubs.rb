require "json"

# Helpers for stubbing CloudStack HTTP responses.
#
# Every CloudStack request carries a generated `signature` query parameter, so
# stubs match on the `command` parameter with `hash_including` rather than on a
# full URL.
module ApiStubs
  API_ENDPOINT = "https://cloudstack.test/client/api".freeze

  # WebMock matches a bare URL only against requests with no query string, and
  # every CloudStack request carries one. Match on the endpoint prefix instead.
  ANY_REQUEST = %r{\Ahttps://cloudstack\.test/client/api}.freeze

  # Stub a CloudStack command with an already-shaped response body.
  #
  #   stub_command("listZones", "listzonesresponse" => { "count" => 1, ... })
  def stub_command(command, body, status: 200)
    stub_request(:get, API_ENDPOINT)
      .with(query: hash_including("command" => command))
      .to_return(
        status: status,
        body: JSON.generate(body),
        headers: { "Content-Type" => "application/json" }
      )
  end

  # Stub a command using CloudStack's usual envelope:
  # { "<command>response" => { "count" => n, "<entity>" => [...] } }
  def stub_list(command, entity, items, count: nil, extra: {})
    inner = { "count" => count || items.size, entity => items }.merge(extra)
    stub_command(command, { "#{command.downcase}response" => inner })
  end

  # Stub the initial async command, then the queryAsyncJobResult polls.
  #
  # `polls` is an array of jobstatus payloads returned in order.
  def stub_async(command, job_id: "job-1", polls: [])
    stub_command(command, { "#{command.downcase}response" => { "jobid" => job_id } })

    responses = polls.map do |poll|
      {
        status: 200,
        body: JSON.generate("queryasyncjobresultresponse" => poll),
        headers: { "Content-Type" => "application/json" }
      }
    end

    stub_request(:get, API_ENDPOINT)
      .with(query: hash_including("command" => "queryAsyncJobResult"))
      .to_return(*responses)
  end

  # A completed async job payload.
  def job_success(result)
    { "jobstatus" => 1, "jobresult" => result }
  end

  # A failed async job payload.
  def job_failure(errortext, code: 530)
    {
      "jobstatus" => 2,
      "jobresultcode" => code,
      "jobresult" => { "errortext" => errortext }
    }
  end

  # An in-flight async job payload.
  def job_pending
    { "jobstatus" => 0 }
  end

  # Parsed query parameters of the most recent request, for asserting on how
  # a request was built rather than only on what came back.
  def last_request_params
    signature = WebMock::RequestRegistry.instance.requested_signatures.hash.keys.last
    raise "no request was made" if signature.nil?

    # CGI.parse was removed in Ruby 4.0; only CGI.escape/unescape remain.
    URI.decode_www_form(signature.uri.query.to_s)
       .each_with_object(Hash.new { |hash, key| hash[key] = [] }) do |(key, value), acc|
         acc[key] << value
       end
  end
end
