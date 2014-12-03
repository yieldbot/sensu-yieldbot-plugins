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
#       "remove_client": true,
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

require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-handler'
require 'json'

#
# == Graceful Shutdown Handler
#
class GracefulShutdownHandler < Sensu::Handler
  def filter; end

  # Get basic information from the system to be used
  # to create a stash
  def build_stash
    @client       = @event['client']['name']
    check         = @event['check']
    expires       = settings['graceful-shutdown']['expires']
    keyspace      = settings['graceful-shutdown']['keyspace']
    @remove_client = settings['graceful-shutdown']['remove_client']

    @body = {
      'path'        => "#{keyspace}/#{@client}",
      'expire'      => expires,
      'content'     => check
    }
  end

  # Build the stash and delete the client if configured
  # to do so
  def handle
    build_stash
    api_request(:POST, '/stashes') do |req|
      req.body = @body.to_json
    end

    # Remove the client (if configured to do so)
    delete_sensu_client!(@client) if @remove_client
  end

  # Delete the sensu client using an api request
  #
  # ==== Attributes
  #
  # * +client+ - the machine name to delete
  def delete_sensu_client!(client)
    api_request(:DELETE, "/clients/#{client}")
  end
end
