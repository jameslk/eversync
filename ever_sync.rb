# EverSync
# Author: James Koshigoe
#
# Description:
#    This simple script continuously syncs (one-way) a local directory's contents with another directory or remote
#    resource by using rsync. It uses the em-dir-watcher gem to be notified upon changes. For each file changed, it
#    finds the directory and syncs it to the remote resource. If multiple files were modified at once, it finds the
#    lowest directory in the tree structure and syncs that.
#
#    Note: The directory monitoring handler can't detect empty directories, so an empty file needs to be added to them
#    to pick them up.
#
# License:
#    zlib/libpng License. Copyright (c) 2012 James Koshigoe.
#
#    This software is provided 'as-is', without any express or implied
#    warranty.  In no event will the authors be held liable for any damages
#    arising from the use of this software.
#
#    Permission is granted to anyone to use this software for any purpose,
#    including commercial applications, and to alter it and redistribute it
#    freely, subject to the following restrictions:
#
#    1. The origin of this software must not be misrepresented; you must not
#    claim that you wrote the original software. If you use this software
#    in a product, an acknowledgment in the product documentation would be
#    appreciated but is not required.
#    2. Altered source versions must be plainly marked as such, and must not be
#    misrepresented as being the original software.
#    3. This notice may not be removed or altered from any source distribution.

# Enter the location of rsync and any other relevant binaries for the script to use

ENV['PATH'] += ";C:/cygwin/bin"

# This is the location of where files are being monitored for changes and transfered from. It must be a local system
# path and not a remote resource.

LOCAL_DIR = "C:/path/to/my/files"

# This is the location the files are transfered to. It can be a local system path or remote resource. See rsync's
# documentation on how to construct remote resource paths.

REMOTE_DIR = "username@localhost:/remote/path"

# These are the options that should be passed to rsync for every transfer. For example, the SSH port can be specified
# here.

RSYNC_OPTIONS = "-t -v -z -e 'ssh -p 22'"

# This is the command to run rsync.
#
# Note, you can send your SSH password to a remote resource without using key authentication using this command:
#   sshpass -p 'sshpassword' rsync

# This is obviously a bad idea from a security standpoint however, since it will be sent in plaintext.

RSYNC_COMMAND = "rsync"

# List of exclusion filters to use. They're similar to rsync's filters, but not all features are included:
# - Regular text will match any part of a path
# - A filter starting with / will only match if the path has the same beginning
# - A filter ending with / will only match if the path has the same ending
# - ? matches any single character in a path that isn't a /
# - * matches any number of characters in a path until it hits the first /
# - ** matches any number of characters in a path, including /

EXCLUSION_FILTERS = ['.git*']

# Setting this to true will make all transfers dry runs. No files are changed.

SIMULATE = false

# --- Don't edit below ---

require 'rubygems'
require 'em-dir-watcher'

class EverSync
  attr_accessor :rsync_command, :exclusion_filters

  def initialize(local_dir, remote_dir, global_options = nil)
    @rsync_command = 'rsync'
    @local_dir = strip_end_slash(local_dir) + '/'
    @local_dir_expanded = File.expand_path(@local_dir)
    @remote_dir = remote_dir
    @global_options = global_options
    @is_simulating = false
    @exclusion_filters = []
  end

  def enable_simulation()
    @is_simulating = true
    self
  end

  def disable_simulation()
    @is_simulating = false
    self
  end

  def add_exclusion(filter)
    @exclusion_filters << filter
    self
  end

  def add_exclusion_file(path)
    @exclusion_filters << File.read(path).split(/\r?\n/)
    self
  end

  def start()
    puts 'Starting synchronization'

    resync

    EM.run do
      dw = EMDirWatcher.watch @local_dir_expanded, :grace_period => 0.5 do |paths|
        resync paths
      end

      puts "EverSync is synchronizing '#{@local_dir}' to '#{@remote_dir}'"
    end

    self
  end

  def strip_start_slash(path)
    path.sub /^\//, ''
  end

  def strip_end_slash(path)
    path.sub /\/$/, ''
  end

  def is_remote_path?(path)
    path =~ /[a-zA-Z0-9-]+@.+?:\/.*/
  end

  def translate_to_rsync_path(path)
    if is_remote_path?(path)
      path.gsub /\s/, '\\ ' #white spaces need to escaped with backslashes for the remote shell only
    elsif ENV['OS'].downcase =~ /windows/
      IO.popen("cygpath #{path}").read.strip.gsub /\s/, ' '
    end
  end

  def path_in_filter?(path, filter)
    regexp = ''

    i = 0
    stars = 0
    filter.each_byte do |ascii|
      char = ascii.chr

      if char == '*'
        stars += 1
      else
        if stars >= 2
          regexp += '.*?'
        elsif stars >= 1
          regexp += '[^\/]*?'
        end

        if char == '/' && i == 0
          regexp = '^\/?'
        elsif char == '/' && (i + 1) == filter.length
          regexp += '\/?$'
        elsif char == '?'
          regexp += '[^\/]?'
        else
          regexp += Regexp.escape char
        end

        stars = 0
      end

      i += 1
    end

    Regexp.new(regexp) =~ path
  end

  def remove_excluded_paths(paths)
    paths.delete_if do |path|
      @exclusion_filters.reduce(false) do |status, filter|
        status || path_in_filter?(path, filter)
      end
    end
  end

  def resync(files = nil)
    options = ''
    if @is_simulating
      options += ' -n'
    end

    files_input = ''
    if files && (files = remove_excluded_paths(files))
      options += ' --include-from=- --exclude=*'

      filters = []
      files.each do |file|
        file = '/' + strip_end_slash(file)
        begin
          filters << file
        end while (file = File.dirname(file)) != '/'
      end

      files_input = filters.join("\n")
    else
      options += ' --exclude-from=-'
      files_input = @exclusion_filters.join("\n")
    end

    local_dir = strip_end_slash(translate_to_rsync_path(@local_dir)) + '/'
    remote_dir = translate_to_rsync_path(@remote_dir)

    command = "#{@rsync_command} -r --delete --ignore-errors --force #{options} #{@global_options} '#{local_dir}' '#{remote_dir}'"

    puts command
    puts "\n#{files_input}"

    IO.popen command, mode='r+' do |io|
      io.write files_input
      io.close_write
      puts io.read
    end
  end
end

# --- Execution ---

ever_sync = EverSync.new LOCAL_DIR, REMOTE_DIR, RSYNC_OPTIONS
ever_sync.exclusion_filters = EXCLUSION_FILTERS

ever_sync.rsync_command = RSYNC_COMMAND

if SIMULATE
  ever_sync.enable_simulation
end

ever_sync.start
