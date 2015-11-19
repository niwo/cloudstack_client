#!/usr/bin/env ruby

require "cloudstack_client/api"
require "benchmark"
require "json"

GC.disable

memory_before = `ps -o rss= -p #{Process.pid}`.to_i/1024
gc_stat_before = GC.stat

time = Benchmark.realtime do
  100.times do
    api = CloudstackClient::Api.new
    command = "listVirtualMachines"
    api.command_supports_param?(command, "id")
    api.required_params(command)
    api.all_required_params?("deployVirtualMachine", { name: "test", templateid: 1 })
  end
end

gc_stat_after = GC.stat
memory_after = `ps -o rss= -p #{Process.pid}`.to_i/1024

puts({
  time: time.round(2),
  gc_count: gc_stat_after[:count] - gc_stat_before[:count],
  memory: "%dM" % (memory_after - memory_before)
}.to_json)
