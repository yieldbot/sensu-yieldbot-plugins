#! /usr/bin/env ruby
#
# Graceful Shutdown Handler
# ===
#
# DESCRIPTION:
#   This handler is responsible for handling graceful shutdown messages.
#   Upon receipt of the message a stash entry is created, signifying
#   that the client is starting to shutdown.
#
#   This stash entry can be used as metadata by keepalive handlers
#   to determine if a machine was gracefully shutdown or not.
#
# OUTPUT:
#   plain-text
#
# PLATFORMS:
#   all
#
# DEPENDENCIES:
#   gem: sensu-handler
#
# Requires a Sensu configuration snippet:
#   {
#     "graceful-shutdown": {
#       "expires": 120,
#       "keyspace": "graceful-shutdown",
#     }
#   }
#
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

require 'sensu-handler'
require 'json'

class GracefulShutdownHandler < Sensu::Handler

  def filter; end

  def handle
    # Get the data we need to build the stash
    client    = @event['client']['name']
    check     = @event['check']
    expires   = settings['graceful-shutdown']['expires']
    keyspace  = settings['graceful-shutdown']['keyspace']

    body = {
      'path'        => "#{keyspace}/#{client}",
      'expire'      => expires,
      'content'     => check
    }

    # Create a stash for the node via the HTTP API
    api_request(:POST, '/stashes') do |req|
      req.body = body.to_json
    end
  end
end
