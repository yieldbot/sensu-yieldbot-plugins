#! /usr/bin/env ruby

require 'json'
require 'socket'

hostname = 'localhost'
port = '3030'
socket_input = '{ "name": "api_call", "output": "delete", "handler": "sensu-api-handler"}'

a = TCPSocket.open(hostname, port)

a.print socket_input

a.close
