#! /usr/bin/env ruby
#
# Checks ElasticSearch cluster status
# ===
#
# DESCRIPTION:
#   This plugin checks the ElasticSearch cluster status, using its API.
#   This plugin is designed towards the Elasticsearch API Version 1.x
#
# OUTPUT:
#   plain-text
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: sensu-plugin
#   gem: rest-client
#   gem: json
#
# #YELLOW
# needs usage
# USAGE:
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
require 'sensu-plugin/check/cli'
require 'rest-client'
require 'json'

#
# == Elastic Search Cluster Status
#
class ESClusterStatus < Sensu::Plugin::Check::CLI
  option :scheme,
         description: 'URI scheme',
         long: '--scheme SCHEME',
         default: 'http'

  option :server,
         description: 'Elasticsearch server',
         short: '-s SERVER',
         long: '--server SERVER',
         default: 'localhost'

  option :port,
         description: 'Port',
         short: '-p PORT',
         long: '--port PORT',
         default: '9200'
  #
  # Get an ES resource
  #
  # ==== Attributes
  #
  # * +resource+ - the path to pass into the rest client
  #
  def get_es_resource(resource)
    r = RestClient::Resource.new("#{config[:scheme]}://#{config[:server]}:\
    #{config[:port]}/#{resource}", timeout: 45)
    JSON.parse(r.get)
  rescue Errno::ECONNREFUSED
    warning 'Connection refused'
  rescue RestClient::RequestTimeout
    warning 'Connection timed out'
  end

  # If the node an ES master it will return TRUE
  #
  def master?
    state = get_es_resource("/_cluster/state?filter_routing_table=true&\
    filter_metadata=true&filter_indices=true&\
    filter_blocks=true&filter_nodes=true")
    local = get_es_resource('/_nodes/_local')
    local['nodes'].keys.first == state['master_node']
  end

  # Get the status of the ES node
  #
  def find_status
    health = get_es_resource('/_cluster/health')
    health['status'].downcase
  end

  # Determine if the node is a master node and if so
  # get the cluster status, if not then opout
  #
  # [note]
  # <b>Metrics/MethodLength</b> is disabled due to the method only
  # having a single purpose
  def run # rubocop:disable MethodLength
    if master?
      case find_status
      when 'green'
        ok 'Cluster is green'
      when 'yellow'
        warning 'Cluster is yellow'
      when 'red'
        critical 'Cluster is red'
      end
    else
      ok 'Not the master'
    end
  end
end
