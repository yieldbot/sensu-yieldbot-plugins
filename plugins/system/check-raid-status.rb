#! /usr/bin/env ruby

# Exit status codes
EXIT_OK = 0
EXIT_WARNING = 1
EXIT_CRIT = 2
exit_code = EXIT_OK


RAID_INFO = "/Users/mjones/projects/elzar/org_cookbooks/monitor/data.test"

def read_file(raid_info)
  a = File.open(raid_info,"r")
  data = a.read
  a.close
  return data
end

raid_status= read_file(RAID_INFO)

matt_test = raid_status.split(/(md[0-9]*)/)

h = Hash.new
n = 0
k = ""
v = ""

matt_test.each do |data|
  if n.even? and n != 0
    v = data
    h.store(k,v)
  elsif n.odd?
    k = data
  end
  n = n + 1
end

h.each do |key, value|
  raid_state = value.split()[1]
  total_dev = value.match(/[0-9]*\/[0-9]*/).to_s[0]
  working_dev = value.match(/[0-9]*\/[0-9]*/).to_s[2]
  failed_dev = value.match(/\[[U,_]*\]/).to_s.count "_"
  recovery_state = value.include? "recovery"
  puts recovery_state.inspect

  line_out =  "#{key} is #{raid_state}
               #{total_dev} total devices
               #{working_dev} working devices
               #{failed_dev} failed devices"
  # OPTIMIXE
  #   this should/can be written as a switch statement
  if raid_state == "active" && working_dev >= total_dev && !recovery_state
    puts line_out
  elsif raid_state == "active" && working_dev < total_dev && recovery_state
    puts line_out.concat " \n\t\t *RECOVERING*"
    exit_code = EXIT_WARNING if exit_code <= EXIT_WARNING
  elsif raid_state == "active" && working_dev < total_dev && !recovery_state
    puts line_out.concat "\n\t\t *NOT RECOVERING*"
    exit_code = EXIT_CRIT if exit_code <= EXIT_CRIT
  elsif raid_state != "active"
    puts line_out
    exit_code = EXIT_CRIT if exit_code <= EXIT_CRIT
  end

end
exit(exit_code)
