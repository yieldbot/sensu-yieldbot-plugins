#! /usr/bin/env ruby
#
# Checks for Bongo Metrics
# ===
#
# DESCRIPTION:
#   This plugin checks the Bongo Metric, using its API.
#   
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
# == Bongo Metrics Status
#
class BongoMetricCheck < Sensu::Plugin::Check::CLI
  option :scheme,
         description: 'URI scheme',
         long: '--scheme SCHEME',
         default: 'http'

  option :server,
         description: 'Marathon server',
         short: '-s SERVER',
         long: '--server SERVER',
         default: 'localhost'

  option :port,
         description: 'Port',
         short: '-p PORT',
         long: '--port PORT',
         default: '8080'

  option :app,
         description: 'APP ID',
         short: '-a APP ID',
         long: '--app APP ID',
         default: 'bongo.useast.prod'

  option :consumergroup,
         description: 'Consumer Group Name',
         short: '-c  CONSUMERGROUP',
         long: '--consumergroup CONSUMERGROUP',
         default: 'yield_secor'
  #
  # Get an JSON resource from Bongo
  #
  # ==== Attributes
  #

  def get_marathon_slave(server,port,app)
    r = RestClient::Resource.new("http://#{server}:#{port}/v2/apps/#{app}", timeout: 45)
    JSON.parse(r.get)
  rescue Errno::ECONNREFUSED
    warning 'Connection refused'
  rescue RestClient::RequestTimeout
    warning 'Connection timed out'
  end
  

  def get_bongo_resource(resource)
    r = RestClient::Resource.new("#{resource}", timeout: 45)
    JSON.parse(r.get)
  rescue Errno::ECONNREFUSED
    warning 'Connection refused'
  rescue RestClient::RequestTimeout
    warning 'Connection timed out'
  end

  # Get the status of the cluster 
  #
  def find_status
    app_data = get_marathon_slave(config[:server],config[:port],config[:app])
    host = app_data['app']['tasks'][0]['host']
    port = app_data['app']['tasks'][0]['ports'][0]
    health = get_bongo_resource("http://#{host}:#{port}/v1/kafka/health/#{config[:consumergroup]}")
    case health['status']
      when 0
        ok 'The consumer lag for this cluster is ok'
      when 1
        critical "The consumer lag for this cluster has crossed the threshold #{health['msg']}"
      end
  end

  def run # rubocop:disable MethodLength
    find_status
  end
end
