#! /usr/bin/env ruby

url = ['deves-events.elasticsearch.service.consul', 'deves-aggregation.elasticsearch.service.consul', 'deves-config.elasticsearch.service.consul']
port = ':9200'
#YELLOW
# need to do a tail -1 here to remove the first line which contains the word 'index'
cmd = '/_cat/indices?v'

valid_index = {}
dupe_index = {}

file_list = ['events', 'agg', 'config']
file_list.each do |u|
  input = File.open(u, 'r')
  index_arr = input.read.split("\n")
  # url.each do |u|
  # data = `curl #{ u }#{ port }#{ cmd }`
  index_arr.each do |t|
    t = t.split[1]
    # puts t
    if valid_index.key?(t)
      dupe_index[t] = [] unless dupe_index[t].is_a?(Array)
      dupe_index[t] << u
      dupe_index[t] << valid_index[t] unless dupe_index[t].include?(valid_index[t])
    else
      valid_index[t.split[1]] = u
    end
  end
end

if defined? dupe_index
  puts 'There were dupes'
  dupe_index.each do |k, v|
    puts "#{ k } is on #{ v }"
  end
  exit(2)
else
  puts 'All indexes are unique'
  exit(0)
end
