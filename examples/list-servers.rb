#! /usr/bin/env ruby

#########################################
# playing around with the cloudstack
# api, (C) 2012, Nik Wolfgramm
#

require 'yaml'
require 'rainbow'
require 'require_relative'
require_relative '../lib/cloudstack_client'
require_relative '../lib/ssh_command'

#########################################
# Load API secrets from config file
#
options = CloudstackClient::ConnectionHelper.load_configuration()

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
rescue SystemExit, Interrupt
  raise
rescue Exception => e
  puts
  puts "Error connecting to cloudstack:"
  puts e.message
  exit
end

servers = cs.list_servers
puts
puts "Total number of servers: #{servers.size}"
servers.each do |server|
  puts "- #{server["name"]}"
end
