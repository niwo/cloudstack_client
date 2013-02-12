#! /usr/bin/env ruby

require 'yaml'
require 'rainbow'
require 'require_relative'
require_relative '../lib/ssh_command'

#########################################
# defining helper functions
#
def print_options(options, attr = 'name')
  options.to_enum.with_index(1).each do |option, i|
    puts "#{i}: #{option[attr]}"
  end 	
end

begin
  puts "Please provide the IP of the server".background(:blue)
  server_IP = gets.chomp

  puts "Install the puppet client".color(:yellow)
  server_connection = { host: server_IP, username: "root", password: "blahblah" }
  puts SshCommand.run(server_connection, "yum -y install puppet").color(:green)

  puts "Create a cert request on the client".color(:yellow)
  puts SshCommand.run(server_connection, "puppet agent --test --waitforcert=0").color(:green)

  puts "Sign request on the puppetmaster".color(:yellow)
  sign_output = %x[puppet cert --sign --all]
  puts sign_output

  puts "Puppet should run now on #{server_IP}:".color(:yellow)
  puts SshCommand.run(server_connection, "puppet agent --test").color(:green)

  puts "Finish!".color(:green)
rescue Exception => e
  puts
  puts "Error".color(:red)
  puts e.message
end