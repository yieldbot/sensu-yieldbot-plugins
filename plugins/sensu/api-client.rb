#! /usr/bin/env ruby
#
# Sensu Api Client
# ===
#
# DESCRIPTION:
#   This plugin will check a stash for a delete value and expire.
#   it after 60 seconds.
#   This was adapted from:
#   https://github.com/agent462/sensu-check-stashes
#
# OUTPUT:
#   plain-text
#
# PLATFORMS:
#   all
#
# DEPENDENCIES:
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
require 'json'
require 'socket'

hostname = 'localhost'
port = '3030'
socket_input = '{ "name": "api_call", "output": "delete", "handler": "sensu-handler", "status": 3}'

a = TCPSocket.open(hostname, port)

a.print socket_input

a.close
