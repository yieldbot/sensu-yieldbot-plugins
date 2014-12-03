#! /usr/bin/env ruby
#
# Graceful Shutdown Keepalive Handler
# ===
#
# DESCRIPTION:
#   This handler is responsible for managing keepalives for
#   Graceful Shutdown compliant clients.
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

#
# == Graceful Shutdown Keep Alive Handler
#
class GracefulShutdownKeepAliveHandler < Sensu::Handler
  def filter; end

  # Get basic information from the system to be used
  # to check if a stash exists and if so delete the client
  #
  def handle
    # Get the data we need to query the stash
    client    = @event['client']['name']
    keyspace  = settings['graceful-shutdown']['keyspace']

    # Check if the graceful shutdown stash exists
    if graceful_shutdown_stash_exists?(client, keyspace)
      puts "[Graceful] Stash exists for #{keyspace}/#{client}.  \
      Deleting client."

      # The stash exists, so we can delete the client
      delete_sensu_client!(client)
    else
      puts "[Graceful] No stash exists: #{keyspace}/#{client}"
    end
  end

  # Delete the sensu client using an api request
  #
  # ==== Attributes
  #
  # * +client+ - the machine name to delete
  def delete_sensu_client!(client)
    api_request(:DELETE, "/clients/#{client}")
  end

  # Determine if the graceful shutdown stash exists
  # Will retuen TRUE if it does
  #
  # ==== Attributes
  #
  # * +client+ - the machine name to delete
  # * +keyspace+ - the keysapce we wish to check for the client
  def graceful_shutdown_stash_exists?(client, keyspace)
    api_request(:GET, "/stashes/#{keyspace}/#{client}").code == '200'
  end
end
