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
  
  cli_options[:puppetmaster] = false
  opts.on('-m', '--puppetmaster', 'puppetmaster') do
    cli_options[:puppetmaster] = true
  end
  
  cli_options[:puppetmaster_vip] = nil
  opts.on('-v', '--puppetmaster-vip VIP', 'puppetmaster_vip') do |puppetmaster_vip|
    cli_options[:puppetmaster_vip] = puppetmaster_vip
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

  cli_options[:networks] = nil
  opts.on('-n', '--network-offering NETWORKS', 'network') do |networks|
    cli_options[:networks] = networks
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
networks = {}
projects.each do |project_name, project_id|
  networks[project_name] = Hash[*cs_connection.list_networks(project_id).collect {|network| [network['name'], network['id']]}.flatten]
end

if cli_options[:show_available_values]
   puts "PROJECTS:".color(:green)
   pp projects
   puts "TEMPLATES:".color(:green)
   pp templates
   puts "COMPUTE OFFERINGS:".color(:green)
   pp compute_offerings
   puts "NETWORK OFFERINGS:".color(:green)
   pp networks
   puts "AVAILIBILITY ZONES:".color(:green)
   pp zones
  exit
end

if ARGV.empty?
  puts optparse
  exit -1
end
server_name = ARGV[0]

if cli_options[:puppetmaster]
  unless cli_options[:puppetmaster_vip]
    puts "Error: must provide puppetmaster_vip"
    exit
  end
end

server = cs_connection.create_server(
  server_name,
  cli_options[:compute],
  cli_options[:template],
  cli_options[:zone],
  cli_options[:networks].split(',').collect{|network| network.strip},
  projects[cli_options[:project]],
)

puts
puts "Make sure the server is running...".color(:yellow)
cs_connection.wait_for_server_state(server["id"], "Running")
puts "OK!".color(:green)

if cli_options[:puppetmaster]
  vip = cs_connection.get_public_ip_address(
    cli_options[:puppetmaster_vip], 
    projects[cli_options[:project]],
  )

  puts
  puts "Create port forwarding rule for ssh access on the CloudStack firewall...".color(:yellow)
  puts vip
  cs_connection.create_port_forwarding_rule(vip["id"], 22, 'TCP', 22, server["id"])
  puts

  server_connection = {
    host: vip["ipaddress"], username: "root", password: "blahblah",
  }

  sleep 10

  puts
  puts "Provision puppetmaster".color(:yellow)
  puts SshCommand.run(server_connection, "wget http://puppet.swisstxt.ch/provision_puppet.sh; sh provision_puppet.sh;").color(:green)
end
