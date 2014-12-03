#! /usr/bin/env ruby
#
# Check Filesystem Writability Plugin
# ===
#
# DESCRIPTION:
#   Checks that a filesystem is writable. Useful for checking stale NFS mounts.
#
# OUTPUT:
#   plain-text
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: sensu-plugin
#   gem: tempfile
#
# #YELLOW
# needs usage
# USAGE:
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

#
# == Check File System Writable
#
class CheckFSWritable < Sensu::Plugin::Check::CLI
  option :dir,
         description: 'Directory to check for writability',
         short: '-d DIRECTORY',
         long: '--directory DIRECTORY',
         proc: proc { |a| a.split(',') }

  option :auto,
         description: 'Auto discover mount points via fstab',
         short: '-a',
         long: '--auto-discover'

  option :debug,
         description: 'Print debug statements',
         long: '--debug'

  # Create the necessary variables inheriting from the previous calss
  #
  def initialize
    super
    @crit_pt_proc = []
    @crit_pt_test = []
  end

  # Send the proper exit codes and output
  #
  def usage_summary
    if @crit_pt_test.empty? && @crit_pt_proc.empty?
      ok 'All filesystems are writable'
    elsif @crit_pt_test || @crit_pt_proc
      critical "These file systems are not writeable: \
      #{ @crit_pt_test }, #{@crit_pt_proc}"
    end
  end

  # Grab all the VolGroup mount points in the self namespace
  #
  def find_mnt_pts
    `grep VolGroup /proc/self/mounts \
    | awk '{print $2, $4}' | awk -F, '{print $1}' | awk '{print $1, $2}'`
    # `grep VolGroup proc_mounts.test \
    # | awk '{print $2, $4}' | awk -F, '{print $1}' | awk '{print $1, $2}'`
  end

  # Test if all mount points are listed as read/write by proc
  #
  # ==== Attributes
  #
  # * +mount_info+ - an array containing all mount points listed in self
  #
  def rw_in_proc?(mount_info)
    mount_info.each  do |pt|
      @crit_pt_proc <<  "#{ pt.split[0] }" if pt.split[1] != 'rw'
    end
  end

  # Test if all mount points are read/write by writing a file and then
  # reading it back
  #
  # ==== Attributes
  #
  # * +mount_info+ - an array containing all mount points listed in self
  #
  def rw_test?(mount_info)
    mount_info.each do |pt|
      (Dir.exist? pt.split[0]) || (@crit_pt_test << "#{ pt.split[0] }")
      file = Tempfile.new('.sensu', pt.split[0])
      puts "The temp file being written to: #{ file.path }" if config[:debug]
      # #YELLOW
      #  need to add a check here to validate permissions, if none it pukes
      file.write('mops') || @crit_pt_test <<  "#{ pt.split[0] }"
      file.read || @crit_pt_test <<  "#{ pt.split[0] }"
      file.close
      file.unlink
    end
  end

  # This will read all VolGroups from the self namespace and
  # then run the necessary tests against them.
  #
  def auto_discover
    # #YELLOW
    # this will only work for a single namespace as of now
    mount_info = find_mnt_pts.split("\n")
    warning 'No mount points found' if mount_info.length == 0
    # #YELLOW
    #  I want to map this to make eaiser to read for large filesystems
    puts 'This is a list of mount_pts and their current \
    status: ', mount_info if config[:debug]
    rw_in_proc?(mount_info)
    rw_test?(mount_info)
    puts "The critical mount points according to proc \
    are: #{ @crit_pt_proc }" if config[:debug]
    puts "The critical mount points according to actual testing \
    are: #{ @crit_pt_test }" if config[:debug]
  end

  # This will read in the array of directories to test and then
  # attempt to write a file to each and then read it back
  #
  def manual_test
    config[:dir].each do |d|
      (Dir.exist? d) || (@crit_pt_test << "#{ d }")
      file = Tempfile.new('.sensu', d)
      puts "The temp file being written to: #{ file.path }" if config[:debug]
      # #YELLOW
      #  need to add a check here to validate permissions, if none it pukes
      file.write('mops') || @crit_pt_test <<  "#{ d }"
      file.read || @crit_pt_test <<  "#{ d }"
      file.close
      file.unlink
    end
  end

  # If the auto flag is present then run auto_discover
  # If directories are given then run manual_test
  # If not is given or unknown options are used fail gracefully
  #
  def run
    (auto_discover if config[:auto]) || (manual_test if config[:dir]) || \
    (warning 'No directorties to check')
    usage_summary
  end
end
