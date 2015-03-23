#! /usr/bin/env ruby

require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'net/http'
require 'sensu-plugin/check/cli'
require 'sensu-plugin/utils'
require 'json'

#
# Update Lut Pub Info Check
#
class UPdateLutPubInfoCheck < Sensu::Plugin::Check::CLI
  include Sensu::Plugin::Utils

  option :critical,
         description: 'Critical value in seconds',
         short:       '-c SECONDS',
         long:        '--critical SECONDS',
         default:     600

 option :warning,
        description: 'Warning value in seconds',
        short:       '-w SECONDS',
        long:        '--warning SECONDS',
        default:     300


  def api_request(method, path, &blk) # rubocop:disable all
    http = Net::HTTP.new(settings['api']['host'], settings['api']['port'])
    req = net_http_req_class(method).new(path)
    if settings['api']['user'] && settings['api']['password']
      req.basic_auth(settings['api']['user'], settings['api']['password'])
    end
    yield(req) if block_given?
    http.request(req)
  end

  def lut_pub_info # rubocop:disable Metrics/MethodLength
    keyspace = 'update_lut_pub_info'

    # Get a list of the stashes
    response = api_request(:GET, '/stashes')

    # Make sure we are able to retrieve the stashes
    critical 'Lut Pub Update - Unable to retrieve stashes' if response.code != '200'
    warning  'Lut Pub Update - No stash was found' if response.body == '[]'

    all_stashes = JSON.parse(response.body)

    # Filter the stathes
    all_stashes.each do |stash|
      if match = stash['path'].match(/^#{keyspace}\/(.*)/) # rubocop:disable all
        @stash = stash['content']['output']
      end
    end
  end

  def run
  lut_pub_info
  t = Time.now.to_i
  critical "Lut Pub Update finished over #{ config[:critical] } seconds ago" unless t - @stash['last_finish'].to_i < config[:critical].to_i
  warning "Lut Pub Update finished over #{ config[:warning] }" unless t - @stash['last_finish'].to_i < config[:warning].to_i
  ok
  end
end
