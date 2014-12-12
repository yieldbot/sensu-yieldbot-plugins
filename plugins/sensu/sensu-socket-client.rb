#! /usr/bin/env ruby
#
# Sensu Socket Client
# ===
#
# DESCRIPTION:
#   This utilizes the unsecure port within Sensu Client to send a check to the
#   Sensu Server.
#
# OUTPUT:
#   plain-text
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: sensu-plugin
#   gem: json
#
# USAGE:
#
# NOTES:
#
# LICENSE:
#   Copyright 2014 Yieldbot, Inc  <devops@yieldbot.com>
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-plugin/cli'
require 'json'
require 'socket'

#
# == Sensu Socket Client
#
class SensuSocketClient < Sensu::Plugin::CLI
  option :name,
         description: 'The name to use for the check.',
         short: '-n NAME',
         long: '--name NAME',
         default: 'socket-api'

  option :type,
         description: 'The type to use for the check.',
         short: '-t TYPE',
         long: '--type TYPE',
         default: 'status'

  option :handler,
         description: 'The handler(s) to use for the check.',
         short: '-h HANDLER[,HANDLER]',
         long: '--handler HANDLER[,HANDLER]',
         default: 'default',
         proc: proc { |a| a.split(',') }

  option :output,
         description: 'The output to use for the check.',
         short: '-o OUTPUT',
         long: '--output OUTPUT',
         default: ''

  option :status,
         description: 'The status to use for the check.',
         short: '-s STATUS',
         long: '--status STATUS',
         default: 0,
         proc: proc(&:to_i)

  # Send a JSON string to the local sensu client for transport
  # to the sensu server
  #
  def run  # rubocop:disable MethodLength
    data = {
      'name'      => config[:name],
      'type'      => config[:type],

      # Convert to an array here explicilty incase a single handler is given
      'handlers'  => Array(config[:handler]),
      'output'    => config[:output],
      'status'    => config[:status]
    }

    # Open the socket
    socket = TCPSocket.new '127.0.0.1', 3030

    # Dump the data to the socket
    socket.print data.to_json

    # Close the socket
    socket.close

    ok
  end

  def output(*_args)
    # Noop this function
  end
end
