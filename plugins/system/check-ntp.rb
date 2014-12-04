#! /usr/bin/env ruby
#
# Check NTP Offset
# ===
#
# DESCRIPTION:
#   This plugin provides a method for checking the NTP offset.
#
# OUTPUT:
#   plain-text
#
# PLATFORMS:
#   all
#
# DEPENDENCIES:
#   gem: sensu-plugin
#
# USAGE:
#   ../check-ntp.rb
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

class CheckNTP < Sensu::Plugin::Check::CLI

  option :warn,
         short: '-w WARN',
         long:  '--warn WARN',
         proc: proc(&:to_i),
         default: 10

  option :crit,
         short: '-c CRIT',
         long:  '--crit CRIT',
         proc: proc(&:to_i),
         default: 100

  def run
    begin
      offset = `ntpq -c "rv 0 offset"`.split('=')[1].strip.to_f
    rescue
      unknown 'NTP command Failed'
    end

    critical if offset >= config[:crit] || offset <= -config[:crit]
    warning if offset >= config[:warn] || offset <= -config[:warn]
    ok

  end
end
