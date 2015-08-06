#! /usr/bin/env ruby
#
# metrics-bongo.rb
#
# DESCRIPTION:
#
#
# OUTPUT:
#   JSON
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: sensu-plugin
#   gem: rest-client
#
# USAGE:
#   #YELLOW
#
# NOTES:
#
# LICENSE:
#   Copyright (c) 2015,Yieldbot <devops@yieldbot.com>
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'sensu-plugin/metric/cli'
require 'json'
require 'rest-client'

#
# Get a set of metrics from an app running in Mesos
#
class MesosAppMetrics < Sensu::Plugin::Metric::CLI::Statsd
  option :server,
         description: 'The consul dns name of the mesos server',
         short: '-s SERVER',
         long: '--server SERVER'

  option :port,
         short: '-p PORT',
         long: '--port PORT',
         description: 'The port used to query mesos'

  option :app,
         short: '-a APP',
         long: '--app APP',
         description: 'The name of the app to get metrics from'

  # Acquire the slave that a particular app is running on
  #
  def acquire_app_slave
    # consul dns should always be used
    server = config[:server] || 'us-east-1-perpetuum.mesos-marathon.service.consul'
    # the default port is the one supplied by consul
    port   = config[:port] || '443'
    app    = config[:app]
    @failures = []

    # break out if the client fails to connect to the mesos master
    begin
        r = RestClient::Resource.new("https://#{server}:#{port}/v2/apps/#{app}", timeout: 10, verify_ssl: false).get
        if r.code != 200
          @failures << "#{server} returned a #{r.code} status code"
        end
      rescue Errno::ECONNREFUSED, RestClient::ResourceNotFound, SocketError
        @failures << "#{server} connection was refused"
      rescue RestClient::RequestTimeout
        @failures << "#{server} connection timed out"
      end
    JSON.parse(r)['app']['tasks'][0]['host']
  end

  # reterive the metrics from the app
  #
  def acquire_metrics(current_slave)
    JSON.parse(`curl -s -k http://#{current_slave}:31520/v1/kafka/metrics`)
  end

  def run
    current_slave = acquire_app_slave
    critical @failures unless @failures.nil?
    acquire_metrics(current_slave).each do |k,v|
      output [k,v].join('.')
    end
    ok
  end
end
