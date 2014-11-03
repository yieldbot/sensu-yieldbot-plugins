#! /usr/bin/env ruby

require 'sensu-plugin/check/cli'

class CheckESClusterIndex < Sensu::Plugin::Check::CLI

  option :cluster,
    :description => 'Array of clusters to check',
    :short => '-C CLUSTER[,CLUSTER]',
    :long => '--cluster CLUSTER[,CLUSTER]',
    :proc => proc { |a| a.split(',') }

  option :debug,
    :description => 'Debug',
    :short => '-d',
    :long => '--debug'

  def run
    port = ':9200'
    cmd = '/_cat/indices?v | tail -n +2'

    valid_index = {}
    dupe_index = {}

  # file_list = ['events', 'agg', 'config']
  # file_list.each do |u|
  #  input = File.open(u, 'r')
  #  index_arr = input.read.split("\n")
    config[:cluster].each do |u|
      index_arr = `curl -s #{ u }#{ port }#{ cmd }`.split("\n")
      index_arr.each do |t|
        t = t.split[1]
        if valid_index.key?(t)
          dupe_index[t] = [] unless dupe_index[t].is_a?(Array)
          dupe_index[t] << u
          dupe_index[t] << valid_index[t] unless dupe_index[t].include?(valid_index[t])
        else
          valid_index[t] = [] unless valid_index[t].is_a?(Array)
          valid_index[t] << u
        end
      end
    end

    if dupe_index.count > 0
      dupe_index.each do |k, v|
        critical "#{ k } is on #{ v }"
      end
    else
      ok 'All indexes are unique'
    end
  end
end
