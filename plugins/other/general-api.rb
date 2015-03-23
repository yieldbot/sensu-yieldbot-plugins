#! /usr/bin/env ruby

require 'sensu-handler'
require 'json'

class SensuApiHandler < Sensu::Handler

  def filter; end

  def handle
    # Get the data we need to build the stash
    client        = @event['client']['name']
    check         = @event['check']  # this is the content
    expires       = 600  # should be set to one hour
    keyspace      = 'update_lut_pub_info'

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
