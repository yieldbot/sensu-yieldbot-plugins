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
#   all
#
# DEPENDENCIES:
#   gem: sensu-plugin
#   gem: rest-client
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

require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-plugin/check/cli'
require 'rest-client'
require 'json'

class ESClusterStatus < Sensu::Plugin::Check::CLI

  option :scheme,
         :description => 'URI scheme',
         :long => '--scheme SCHEME',
         :default => 'http'

  option :server,
         :description => 'Elasticsearch server',
         :short => '-s SERVER',
         :long => '--server SERVER',
         :default => 'localhost'

  option :port,
         :description => 'Port',
         :short => '-p PORT',
         :long => '--port PORT',
         :default => '9200'

  def get_es_resource(resource)
    begin
      r = RestClient::Resource.new("#{config[:scheme]}://#{config[:server]}:#{config[:port]}/#{resource}", :timeout => 45)
      JSON.parse(r.get)
    rescue Errno::ECONNREFUSED
      warning 'Connection refused'
    rescue RestClient::RequestTimeout
      warning 'Connection timed out'
    end
  end

  def is_master
    state = get_es_resource('/_cluster/state?filter_routing_table=true&filter_metadata=true&filter_indices=true&filter_blocks=true&filter_nodes=true')
    local = get_es_resource('/_nodes/_local')
    local['nodes'].keys.first == state['master_node']
  end

  def get_status
    health = get_es_resource('/_cluster/health')
    health['status'].downcase
  end

  def run
    if is_master
      case get_status
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
