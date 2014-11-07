#! /usr/bin/env ruby

require 'json'
require 'socket'

hostname = 'localhost'
port = '3030'
socket_input = '{ "name": "test_check", "output": "some output", "status": 1 }'

a = TCPSocket.open(hostname, port)

a.print socket_input

a.close
