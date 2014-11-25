#! /usr/bin/env ruby
#
# Sensu Socket Client
# ===
#
# DESCRIPTION:
#   This script utilizes the unsecure port within Sensu Client to send a check to the
#   Sensu Server.
#
# OUTPUT:
#   plain-text
#
# PLATFORMS:
#   all
#
# DEPENDENCIES:
#   gem: sensu-plugin
#   gem: json
#
# #YELLOW
# needs example command
# EXAMPLES:
#
#
# NOTES:
#
# LICENSE:
#   Copyright 2014 Yieldbot, Inc  <devops@yieldbot.com>
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'sensu-plugin/cli'
require 'json'
require 'socket'

class SensuSocketClient < Sensu::Plugin::CLI
  option :name,
         :description => 'The name to use for the check.',
         :short       => '-n NAME',
         :long        => '--name NAME',
         :default     => 'socket-api'

  option :type,
         :description => 'The type to use for the check.',
         :short       => '-t TYPE',
         :long        => '--type TYPE',
         :default     => 'status'

  option :handler,
         :description => 'The handler(s) to use for the check.',
         :short       => '-h HANDLER[,HANDLER]',
         :long        => '--handler HANDLER[,HANDLER]',
         :default     => 'default',
         :proc        => proc { |a| a.split(',') }

  option :output,
         :description => 'The output to use for the check.',
         :short       => '-o OUTPUT',
         :long        => '--output OUTPUT',
         :default     => ''

  option :status,
         :description => 'The status to use for the check.',
         :short       => '-s STATUS',
         :long        => '--status STATUS',
         :default     => 3,
         :proc        => proc { |a| a.to_i }

  def run
    data = {
      'name'      => config[:name],
      'type'      => config[:type],

      # Convert to an array here explicilty incase a single handler is given
      'handlers'  => Array(config[:handler]),
      'output'    => config[:output],
      'status'    => config[:status],
    }

    # Open the socket
    socket = TCPSocket.new '127.0.0.1', 3030

    # Dump the data to the socket
    socket.print data.to_json

    # Close the socket
    socket.close

    ok
  end
end
