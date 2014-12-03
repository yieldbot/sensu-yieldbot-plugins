#! /usr/bin/env ruby
#
# Graceful Shutdown Monitor
# ===
#
# DESCRIPTION:
#   This check is responsible for removing clients from Sensu who have
#   graceful shutdown stashes associated with them, in an effort
#   to reduce the chance of a keepalive handler firing for them.
#
# PLATFORMS:
#   all
#
# DEPENDENCIES:
#   gem: sensu-plugin
#
# NOTES:
#   This check should be run where it can have access to the API server,
#   which is usually the sensu-server.
#
#   This check should be run more frequently than the warning keepalive
#   handler time.
#
# LICENSE:
#   Copyright 2014 Yieldbot, Inc  <devops@yieldbot.com>
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'net/http'
require 'sensu-plugin/check/cli'
require 'sensu-plugin/utils'
require 'json'

#
# == Graceful Shutdown Check
#
class GracefulShutdownCheck < Sensu::Plugin::Check::CLI
  include Sensu::Plugin::Utils

  # #YELLOW
  # unused arg
  # needs docs
  def api_request(method, path, &blk) # rubocop:disable all
    http = Net::HTTP.new(settings['api']['host'], settings['api']['port'])
    req = net_http_req_class(method).new(path)
    if settings['api']['user'] && settings['api']['password']
      req.basic_auth(settings['api']['user'], settings['api']['password'])
    end
    yield(req) if block_given?
    http.request(req)
  end

  #
  # #YELLOW
  # needs docs
  def delete_sensu_client!(client)
    api_request(:DELETE, "/clients/#{client}")
  end

  #
  # #YELLOW
  # needs docs
  def graceful_clients # rubocop:disable Metrics/MethodLength
    keyspace = settings['graceful-shutdown']['keyspace']

    # Get a list of the stashes
    response = api_request(:GET, '/stashes')

    # Make sure we are able to retrieve the stathses
    critical 'Unable to retrieve stashes' if response.code != '200'

    #
    all_stashes = JSON.parse(response.body)

    # Filter the stathes
    filtered_stashes = []
    all_stashes.each do |stash|
      if match = stash['path'].match(/^#{keyspace}\/(.*)/) # rubocop:disable all
        filtered_stashes << match.captures[0]
      end
    end

    filtered_stashes
  end

  def run
    graceful_clients.each do |client|
      delete_sensu_client!(client)
    end
    ok
  end
end
