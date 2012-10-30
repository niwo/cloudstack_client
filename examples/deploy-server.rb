#! /usr/bin/env ruby

#########################################
# playing around with the cloudstack
# api, (C) 2012, Nik Wolfgramm
#

require 'yaml'
require 'rainbow'
require 'require_relative'
require_relative '../lib/cloudstack_client'
require_relative '../lib/connection_helper'
require_relative '../lib/ssh_command'

#########################################
# Load API secrets from config file
#
options = CloudstackClient::ConnectionHelper.load_configuration()

#########################################
# defining helper functions
#
def print_options(options, attr = 'name')
  options.to_enum.with_index(1).each do |option, i|
    puts "#{i}: #{option[attr]}"
  end 	
end

begin
  #######################################
  # Create a connection using the
  # CloudStack client
  #
  cs = CloudstackClient::Connection.new(
    options[:cloudstack_url],
    options[:cloudstack_api_key],
    options[:cloudstack_secret_key]
  )
  server_offerings = cs.list_service_offerings
  templates = cs.list_templates('featured')
  projects = cs.list_projects
  zones = cs.list_zones
rescue SystemExit, Interrupt
  raise
rescue Exception => e
  puts
  puts "Error connecting to cloudstack:"
  puts e.message
  exit
end

begin
  #########################################
  # Run command over the cloudtsack api
  #
  puts
  puts %{We are going to deploy a new server on CloudStack and...
   - assign a public IP address
   - create a firewall rule for SSH and HTTP access
   - connect to the server and install the puppet client}.color(:magenta)
  puts

  print "Please provide a name for the new server".background(:blue)
  puts " (spaces or special characters are NOT allowed): "
  server_name = gets.chomp

  if projects.size > 0
    puts "Select a project".background(:blue)
    print_options(projects)
    project = gets.chomp.to_i - 1
  end

  puts "Select a computing offering:".background(:blue)
  print_options(server_offerings)
  service_offering = gets.chomp.to_i - 1

  puts "Select a template:".background(:blue)
  print_options(templates)
  template = gets.chomp.to_i - 1

  puts "Select a network:".background(:blue)
  project_id = projects[project]['id'] rescue nil
  networks = cs.list_networks(project_id)
  print_options(networks)
  network = gets.chomp.to_i - 1

  puts "Select a availability zone:".background(:blue)
  print_options(zones)
  zone = gets.chomp.to_i - 1

  puts
  puts "Create a new server on CloudStack...".color(:yellow) + " (#{options[:cloudstack_url]})"
  server = cs.create_server(
		  server_name,
		  server_offerings[service_offering]["name"],
		  templates[template]["name"],
		  zones[zone]["name"],
		  [networks[network]["name"]],
	          project_id
	  )
  puts
  puts "server #{server["name"]} has been created.".color(:green)

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

  puts "Finish!".color(:green)
rescue Exception => e
  puts
  puts "Error".color(:red)
  puts e.message
end
