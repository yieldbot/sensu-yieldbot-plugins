#! /usr/bin/env ruby
#
# check-build-stats@j
#
# DESCRIPTION:
#   Check lut build stats
#
# OUTPUT:
#   plain-text
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: json
#   gem: sensu-plugin
#
# USAGE:
#   check-lut-build-stats.rb
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
require 'json'

#
# == Check Lut Stats
#
class CheckLutStats < Sensu::Plugin::Check::CLI
  option :stats_file,
         description: 'JSON file containing stats',
         short:       '-i FILE',
         long:        '--input FILE',
         default:     '/tmp/update_lut_pub_info'

def acquire_json
  JSON.parse(File.read(config[:stats_file]))
end

  def run
    t = Time.now.to_i
    stats = acquire_json
    critical unless t - stats['last_finish'] < 600
    warning unless t -stats['last_finish'] < 300
    ok

  end
end
