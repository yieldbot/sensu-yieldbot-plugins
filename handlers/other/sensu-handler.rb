#! /usr/bin/env ruby
#
# Sensu Api Handler
# ===
#
# DESCRIPTION:
#   This plugin will check a stash for a delete value and expire.
#   it after 60 seconds.
#   This was adapted from:
#   https://github.com/agent462/sensu-check-stashes
#
# OUTPUT:
#   plain-text
#
# PLATFORMS:
#   all
#
# DEPENDENCIES:
#   gem: sensu-plugin
#   gem: jsoniS
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

require 'sensu-plugin/check/cli'
require 'sensu-plugin/utils'
require 'net/https'
require 'uri'
require 'json'

class SensuHandler < Sensu::Plugin::Check::CLI
  include Sensu::Plugin::Utils

  def api_request(resource, method)
    uri = URI.parse('https://localhost:4567' + resource)
    http = Net::HTTP.new(uri.host, uri.port)
    http.read_timeout = 15
    http.open_timeout = 5
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    case method
    when 'Get'
      req =  Net::HTTP::Get.new(uri.request_uri)
    when 'Delete'
      req =  Net::HTTP::Delete.new(uri.request_uri)
    when 'Create'
      req =  Net::HTTP::Post.new(uri.request_uri)
    end

    sensu_creds
    req.basic_auth(@api_user, @api_pwd)

    begin
      http.request(req)
    rescue Timeout::Error
      puts 'HTTP request has timed out.'
      exit
    rescue StandardError => e
     puts "An HTTP error occurred. #{e}"
     exit
    end
  end

  def create_stash(path)
    resource = '/stashes/shutdown'
    method = 'Create'
    @data = {
      'expire' => 60,
      'path'=> 'shutdown',
      'content' => {
        'client_name' => "#{path}"
      }
    }.to_json
    puts @data
    res = api_request(resource, method)
    response?(res.code) ? JSON.parse(res.body, :symbolize_names => true) : (warning "Failed to create stash #{res.code}")
    puts res.code
  end

  def response?(code)
    case code
    when '200', '202', '204'
      true
    else
      false
    end
  end

  def delete_client(path)
    resource = "/clients/#{path}"
    method = 'Delete'
    res = api_request(resource, method)
    response?(res.code) ? (puts "CLIENT: #{resource} was deleted") : (warning "Deletion of #{resource} failed.")
  end

  def sensu_creds
    sensu_settings = settings
    @api_user = settings['api']['user']
    @api_pwd = sensu_settings['api']['password']
  end

  def run
    event = JSON.parse(STDIN.read, :symbolize_names => true)
    create_stash("#{event[:client][:name]}")
    delete_client("#{event[:client][:name]}")
    ok
  end

end
