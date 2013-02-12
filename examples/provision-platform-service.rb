#! /usr/bin/env ruby

require 'yaml'
require 'rainbow'
require 'require_relative'
require 'optparse'
require 'pp'
require_relative '../lib/cloudstack_client'
require_relative '../lib/connection_helper'
require_relative '../lib/ssh_command'

# Load API secrets from config file
cs_options = CloudstackClient::ConnectionHelper.load_configuration()

cli_options = {}
optparse = OptionParser.new do|opts|
  opts.banner = "Usage: #{$0} name [options]"
  
  cli_options[:show_available_values] = false
  opts.on('-s', '--show-available-values', 'Project') do
    cli_options[:show_available_values] = true
  end

  cli_options[:project] = nil
  opts.on('-p', '--project PROJECT', 'Project') do |project|
    cli_options[:project] = project
  end

  cli_options[:template] = nil
  opts.on('-t', '--template TEMPLATE', 'Template') do |template|
    cli_options[:template] = template
  end

  cli_options[:compute] = nil
  opts.on('-c', '--compute-offering COMPUTE_OFFERING', 'Compute offering') do |compute_offering|
    cli_options[:compute] = file
  end

  cli_options[:network] = nil
  opts.on('-n', '--network-offering NETWORK_OFFERING', 'Network offering') do |network_offering|
    cli_options[:network] = network
  end

  cli_options[:zone] = nil
  opts.on('-z', '--zone FILE', 'Availibility zone') do |zone|
    cli_options[:zone] = zone
  end

  opts.on('-h', '--help', 'Display this screen') do
   puts opts
   exit
  end
end

optparse.parse!
if ARGV.empty?
  puts optpars
  exit -1
end
server_name = ARGV[0]

begin
  cs_connection = CloudstackClient::Connection.new(
    cs_options[:cloudstack_url],
    cs_options[:cloudstack_api_key],
    cs_options[:cloudstack_secret_key]
  )
  projects = Hash[*cs.list_projects.collect {|project| [project['name'], project['id']]}.flatten]
  templates = cs_connection.list_templates('featured').collect{|template| template['name']}
  compute_offerings = cs_connection.list_service_offering.collect{|template| template['name']}
  network_offerings = {}
  projects.each do |project_name, project_id|
    network_offerings[project_name] << cs_connection.list_networks(project_id).collect do |network| 
      network['name']
    end
  end
  zones = cs_connection.list_service_offering.collect{|zone| zone['name']}
rescue SystemExit, Interrupt
  raise
rescue Exception => e
  puts
  puts "Error connecting to cloudstack:"
  puts e.message
  exit -1
end

if cli_options[:show_available_values]
   puts "Projects:"
   pp projects
   puts "Templates:"
   pp templates
   puts "Compute offerings:"
   pp compute_offerings
   puts "Network offerings:"
   pp network_offerings
   puts "Availibility zones:"
   pp zones
  exit
end

begin
  unless projects.has_key? cli_options[:project]
    raise "no such project"
  end
  unless templates.include? cli_options[:template]
    raise "no such template"
  end
  unless compute_offerings.include? cli_options[:compute]
    raise "no such compute offering"
  end
  unless network_offerings.include? cli_options[:network]
    raise "no such network offering"
  end
  unless zone_offerings.include? cli_options[:zone]
    raise "no such zone"
  end
rescue
  puts
  puts "Invalid values supplied:"
  puts e.message
  exit -1
end

begin
  server = cs.create_server(
	  server_name,
		cli_options[:compute],
		cli_options[:template],
		cli_options[:zone],
		[cli_options[:network]],
		projects[cli_options[:project]],
	)

  #puts "Create a cert request on the client".color(:yellow)
  #puts SshCommand.run(server_connection, "puppet agent --test --waitforcert=0").color(:green)

  #puts "Sign request on puppetmaster"
  #sign_output = %x[puppet cert --sign #{server_fqdn}]
  #puts sign_output

  #puts "Puppet should run now on #{server_name}:".color(:yellow)
  #puts SshCommand.run(server_connection, "puppet agent --test").color(:green)
  #puts

  puts "Finish!".color(:green)
rescue Exception => e
  puts
  puts "Error".color(:red)
  puts e.message
end
