#! /usr/bin/env ruby
#
# Check Filesystem Writability Plugin
# ===
#
# DESCRIPTION:
# This plugin checks that a filesystem is writable. Useful for checking for stale NFS mounts.
#
# OUTPUT:
#   plain-text
#
# PLATFORMS:
#   all
#
# DEPENDENCIES:
#   gem: sensu-plugin
#   gem: tempfile
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

require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-plugin/check/cli'
require 'tempfile'

# Exit status codes
$EXIT_OK = 0
$EXIT_WARNING = 1
$EXIT_CRIT = 2

class CheckFSWritable < Sensu::Plugin::Check::CLI

  #YELLOW
  # this should be an array of directories, the goal is not to run a seperate check
  #   for each directory but one check for as many directories as desired
  option :dir,
         :description => 'Directory to check for writability',
         :short => '-d DIRECTORY',
         :long => '--directory DIRECTORY',
         :proc => proc { |a| a.split(',') }


  option :auto,
         :description => 'Auto discover mount points via fstab',
         :short => '-a',
         :long => '--auto-discover'

  option :debug,
         :description => 'Print debug statements',
         :long => '--debug'

  def initialize
    super
    # @@exit_code = $EXIT_OK
    @@crit_pt_proc = []
    @@crit_pt_test = []
  end

  def usage_summary
    if @@crit_pt_test.empty? && @@crit_pt_proc.empty?
      puts 'All filesystems are writable'
      exit($EXIT_OK)
    elsif @@crit_pt_test || @@crit_pt_proc
      puts "The following file systems are not writeable: #{ @@crit_pt_test }, #{@@crit_pt_proc}"
      exit($EXIT_CRIT)
    end
  end

  def get_mnt_pts
     # `grep VolGroup /proc/self/mounts | awk '{print $2, $4}' | awk -F, '{print $1}' | awk '{print $1, $2}'`
     `grep VolGroup proc_mounts.test | awk '{print $2, $4}' | awk -F, '{print $1}' | awk '{print $1, $2}'`
  end

  def is_rw_in_proc(mount_info)
    mount_info.each  do |pt|
      @@crit_pt_proc <<  "#{ pt.split[0] }" if pt.split[1] != 'rw'
    end
  end

  def is_rw_test(mount_info)
    mount_info.each do |pt|
    Dir.exist? pt.split[0] || @@crit_pt_test << "#{ pt.split[0] }"
    file = Tempfile.new('.sensu', pt.split[0])
    puts "The temp file we are writing to is: #{ file.path }" if config[:debug]
    # #YELLOW
    #  need to add a check here to validate permissions, if none it pukes
    file.write('mops') || @@crit_pt_test <<  "#{ pt.split[0] }"
    file.read || @@crit_pt_test <<  "#{ pt.split[0] }"
    file.close
    file.unlink
    end
  end

  def run
    # #YELLOW
    #  set this to be a case statement, it just makes sense here
    if config[:auto]
      # #YELLOW
      # this will only work for a single namespace as of now
      mount_info = Array.new
      mount_info = get_mnt_pts.split("\n")
      # #YELLOW
      #  I want to map this at some point to make it pretty and eaiser to read for large filesystems
      puts 'This is a list of mount_pts and their current status: ', mount_info if config[:debug]
      is_rw_in_proc(mount_info)
      is_rw_test(mount_info)
      puts "The critical mount points according to proc are: #{ @@crit_pt_proc }" if config[:debug]
      puts "The critical mount points according to actual testing are: #{ @@crit_pt_test }" if config[:debug]
    elsif config[:dir]
      puts config[:dir]

      Dir.exist? config[:dir] || @@crit_pt_test << "#{ config[:dir] }"
      file = Tempfile.new('.sensu', config[:dir])
      puts "The temp file we are writing to is: #{ file.path }" if config[:debug]
      # #YELLOW
      #  need to add a check here to validate permissions, if none it pukes
      file.write('mops') || @@crit_pt_test <<  "#{ config[:dir] }"
      file.read || @@crit_pt_test <<  "#{ config[:dir] }"
      file.close
      file.unlink
    end
    usage_summary # unless @crit_fs.empty?
    # usage_summary unless @warn_fs.empty?
    # exit(@exit_code)
  end
end
