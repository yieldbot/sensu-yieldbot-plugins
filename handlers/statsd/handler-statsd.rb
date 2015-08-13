#! /usr/bin/env ruby

require 'sensu-handler'
require 'socket'
require 'json'

class StatsdEvent < Sensu::Handler

  input = JSON.parse(STDIN.read)
  data = input['check']['output']
  server = 'localhost'
  port = 8125

  s = UDPSocket.new
  s.connect(server, port)

  data.each_line do |metric|
    s.send(metric, 0) if metric.match(/^[a-z]/)
  end
end
