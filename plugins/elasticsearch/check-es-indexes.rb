#! /usr/bin/env ruby

url = ['deves-events.elasticsearch.service.consul', 'deves-aggregation.elasticsearch.service.consul', 'deves-config.elasticsearch.service.consul']
port = ':9200'
#YELLOW
# need to do a tail -1 here to remove the first line which contains the word 'index'
cmd = '/_cat/indices?v'

valid_index = {}
dupe_index = {}

#file_list = ['events', 'agg', 'config']
#file_list.each do |u|
  #input = File.open(u, 'r')
  #data = input.read
   url.each do |u|
   data = `curl #{ u }#{ port }#{ cmd }`
  index_arr = data.split("\n")
  index_arr.each do |t|
    if valid_index.key?(t.split[1])
      dupe_index[t.split[1]] = [] unless dupe_index[t.split[1]].kind_of?(Array)
      dupe_index[t.split[1]] << u
      dupe_index[t.split[1]] << valid_index[t.split[1]] unless dupe_index[t.split[1]].include?(valid_index[t.split[1]])
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
