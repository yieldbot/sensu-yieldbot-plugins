#! /usr/bin/env ruby
#
# check-ssh
#
# DESCRIPTION:
#   Check the status and version of SSH
#
# OUTPUT:
#   plain-text
#
# PLATFORMS:
#   all
#
# DEPENDENCIES:
#   gem: socket
#   gem: sensu-plugin
#
# EXAMPLES:
#   check-ssh.rb -h <hostname> -p port
#
# NOTES:
#
# LICENSE:
#   Copyright 2014 Yieldbot, Inc  <devops@yieldbot.com>
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-plugin/check/cli'
require 'socket'

class CheckSSH < Sensu::Plugin::Check::CLI

  option :hostname,
         description: 'The host you wish to connect to',
         short:       '-h HOSTNAME',
         long:        '--hostname HOSTNAME',
         default:     'localhost'

  option :port,
         description: 'The port you wish to connect to',
         short:       '-p PORT',
         long:        '--PORT PORT',
         default:     '22'

  def run
    s = TCPSocket.open(config[:hostname], config[:port]).gets.chop
    critical unless s.include?('SSH')
    ok(s)
  end
end
