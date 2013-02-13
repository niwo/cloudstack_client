#! /usr/bin/env ruby

require 'yaml'
require 'rainbow'
require 'require_relative'
require 'optparse'
require 'pp'
require_relative '../lib/cloudstack_client'
require_relative '../lib/connection_helper'
require_relative '../lib/ssh_command'

cli_options = {}
optparse = OptionParser.new do|opts|
  opts.banner = "Usage: #{$0} name [options]"
  
  cli_options[:show_available_values] = false
  opts.on('-s', '--show-available-values', 'show available values') do
    cli_options[:show_available_values] = true
  end

  cli_options[:project] = nil
  opts.on('-p', '--project PROJECT', 'project') do |project|
    cli_options[:project] = project
  end

  cli_options[:template] = nil
  opts.on('-t', '--template TEMPLATE', 'template') do |template|
    cli_options[:template] = template
  end

  cli_options[:compute] = nil
  opts.on('-c', '--compute-offering COMPUTE_OFFERING', 'compute offering') do |compute_offering|
    cli_options[:compute] = compute_offering
  end

  cli_options[:network] = nil
  opts.on('-n', '--network-offering NETWORK_OFFERING', 'network offering') do |network_offering|
    cli_options[:network] = network_offering
  end

  cli_options[:zone] = nil
  opts.on('-z', '--zone FILE', 'availibility zone') do |zone|
    cli_options[:zone] = zone
  end

  opts.on('-h', '--help', 'display this screen') do
   puts opts
   exit
  end
end
optparse.parse!

cs_options = CloudstackClient::ConnectionHelper.load_configuration()
cs_connection = CloudstackClient::Connection.new(
  cs_options[:cloudstack_url],
  cs_options[:cloudstack_api_key],
  cs_options[:cloudstack_secret_key]
)
projects = Hash[*cs_connection.list_projects.collect {|project| [project['name'], project['id']]}.flatten]
templates = cs_connection.list_templates('featured').collect{|template| template['name']}
compute_offerings = cs_connection.list_service_offerings.collect{|template| template['name']}
zones = cs_connection.list_zones.collect{|zone| zone['name']}
network_offerings = {}
projects.each do |project_name, project_id|
  network_offerings[project_name] = cs_connection.list_networks(project_id).collect do |network| 
    network['name']
  end
end

if cli_options[:show_available_values]
   puts "PROJECTS:".color(:green)
   pp projects
   puts "TEMPLATES:".color(:green)
   pp templates
   puts "COMPUTE OFFERINGS:".color(:green)
   pp compute_offerings
   puts "NETWORK OFFERINGS:".color(:green)
   pp network_offerings
   puts "AVAILIBILITY ZONES:".color(:green)
   pp zones
  exit
end

if ARGV.empty?
  puts optparse
  exit -1
end
server_name = ARGV[0]

server = cs_connection.create_server(
  server_name,
  cli_options[:compute],
  cli_options[:template],
  cli_options[:zone],
  [cli_options[:network]],
  projects[cli_options[:project]],
)

puts
puts "Make sure the server is running...".color(:yellow)
cs.wait_for_server_state(server["id"], "Running")
puts "OK!".color(:green)

puts
puts "Get the fqdn of the server...".color(:yellow)
server_fqdn = cs.get_server_fqdn(server)
puts "fqdn is #{server_fqdn}".color(:green)

puts
puts "Associate an IP address on the CloudStack firewall for the server...".color(:yellow)
ip_addr = cs.associate_ip_address(networks[network]["id"])
puts
puts "IP is #{ip_addr["ipaddress"]}".color(:green)

puts
puts "Create port forwarding rule for ssh access on the CloudStack firewall...".color(:yellow)
cs.create_port_forwarding_rule(ip_addr["id"], 22, 'TCP', 22, server["id"])
puts

puts
puts "Create port forwarding rule for HTTP access on the CloudStack firewall...".color(:yellow)
cs.create_port_forwarding_rule(ip_addr["id"], 80, 'TCP', 80, server["id"])
puts

puts
puts "Install puppet client".color(:yellow)
server_connection = { host: cs.get_server_default_nic(server)["ipaddress"], username: "root", password: "blahblah" }
puts SshCommand.run(server_connection, "yum -y install puppet").color(:green)

puts "Create a cert request on the client".color(:yellow)
puts SshCommand.run(server_connection, "puppet agent --test --waitforcert=0").color(:green)

puts "Sign request on puppetmaster"
sign_output = %x[puppet cert --sign #{server_fqdn}]
puts sign_output

puts "Puppet should run now on #{server_name}:".color(:yellow)
puts SshCommand.run(server_connection, "puppet agent --test").color(:green)
puts
