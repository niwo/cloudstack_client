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

def execute_ssh_commands(server_connection)
  puts "type exit if you are tired typing commands"
  puts "Enter a command:".background(:blue)
  command = gets.chomp
  return if command == "exit" 
  SshCommand.run(server_connection, command) do |output|
    puts output.color(:green)
  end
  execute_ssh_commands(server_connection)
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
  zones = cs.list_zones
  projects = cs.list_projects
rescue SystemExit, Interrupt
  raise
rescue Exception => e
  puts
  puts "Error connecting to cloudstack:"
  puts e.message
  exit
end

trap("SIGINT") { throw :ctrl_c }
begin

  #########################################
  # Run command over the cloudtsack api
  #
  puts
  puts %{Action! We are going to deploy a new server on CloudStack and...
   - assign a public IP address
   - create a firewall rule for SSH access
   - connect to the server and execute commands

  Have fun playing around with the CloudStack API.}.color(:magenta)
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

  project_id = projects[project]['id'] rescue nil
  networks = cs.list_networks(project_id)
  puts "Select a network:".background(:blue)
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
  puts "Associate an IP address on the CloudStack firewall for the server...".color(:yellow)
  ip_addr = cs.associate_ip_address(networks[network]["id"])
  puts
  puts "IP is #{ip_addr["ipaddress"]}".color(:green)

  puts
  puts "Create port forwarding rule for ssh access on the CloudStack firewall...".color(:yellow)
  cs.create_port_forwarding_rule(ip_addr["id"], 22, 'TCP', 22, server["id"])

  puts
  puts
  puts "Accessing server '#{server["name"]}' via ssh. You can execute commands like 'ls -al' or 'ps aux'...".color(:yellow)
  server_connection = { host: ip_addr["ipaddress"], username: "root", password: "blahblah" }
  execute_ssh_commands(server_connection)

  ########################################
  # Delete the created objects again
  #
  puts
  puts "Do you want to remove the created resources? [Y/n]".background(:blue)
  unless gets.chomp == "n"
    puts "Clean up the mess...".color(:yellow)
    puts "delete the server #{server["name"]}".color(:red)
    cs.delete_server(server["name"], project_id)
    puts
    puts "release IP address #{ip_addr["ipaddress"]}".color(:red)
    cs.disassociate_ip_address(ip_addr["id"])
  end
  puts
  puts
  puts "Finish!".color(:green)
rescue SystemExit, Interrupt
  raise
rescue Exception => e
  puts
  puts "bye!"
end
