# EverSync
# Author: James Koshigoe
#
# Description:
#    This simple script continuously syncs (one-way) a local directory's contents with another directory or remote
#    resource by using rsync. It uses the em-dir-watcher gem to be notified upon changes. For each file changed,
#    it executes rsync on the path to sync that specific file only, instead of running rsync over the entire directory
#    structure.
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

ENV['PATH'] += ";C:\\cygwin\\bin"

# This is the location of where files are being monitored for changes and transfered from. It must be a local system
# path and not a remote resource.

LOCAL_DIR = "C:\\path\\to\\my\\files"

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

# Setting this to true will make all transfers dry runs. No files are changed.

SIMULATE = false

# --- Don't edit below ---

require 'rubygems'
require 'open3'
require 'em-dir-watcher'

class EverSync
  attr_accessor :rsync_command

  def initialize(local_dir, remote_dir, rsync_options = nil)
    @rsync_command = 'rsync'
    @local_dir = local_dir
    @remote_dir = remote_dir
    @rsync_options = rsync_options
    @is_simulating = false
  end

  def enable_simulation()
    @is_simulating = true
  end

  def disable_simulation()
    @is_simulating = false
  end

  def start()
    puts 'Starting synchronization'

    resync

    dir = File.expand_path(@local_dir)
    EM.run do
      dw = EMDirWatcher.watch dir, :grace_period => 0.5 do |paths|
        paths.each do |path|
          full_path = File.join(dir, path)
          if File.exists?(full_path)
            resync full_path
          else
            resync File.dirname(full_path), true
          end
        end
      end

      puts "EverSync is synchronizing '#{@local_dir}' to '#{@remote_dir}'"
    end
  end

  def is_remote_path?(path)
    path =~ /[a-zA-Z0-9-]+@.+?:\/.*/
  end

  def strip_start_slash(path)
    path.sub /^\//, ''
  end

  def strip_end_slash(path)
    path.sub /\/$/, ''
  end

  def translate_to_rsync_path(path)
    if is_remote_path?(path)
      path.gsub /\s/, '\\ ' #white spaces need to escaped with backslashes for the remote shell only
    elsif ENV['OS'].downcase =~ /windows/
      IO.popen("cygpath #{path}").read.strip.gsub /\s/, ' '
    end
  end

  def map_to_remote_path(local_path)
    relative_path = translate_to_rsync_path(local_path).gsub /^#{Regexp.quote strip_end_slash(translate_to_rsync_path(@local_dir))}/, ''
    strip_end_slash translate_to_rsync_path(translate_to_rsync_path(@remote_dir) + '/' + strip_start_slash(relative_path))
  end

  def resync(path = nil, delete_sync = false)
    options = "#{options} #{@rsync_options}"
    if @is_simulating
      options += ' -n'
    end

    if path
      local_dir = translate_to_rsync_path path
      remote_dir = map_to_remote_path path

      if delete_sync
        local_dir = strip_end_slash(local_dir) + '/'
        options += ' -r --delete --force'
      end
    else
      options += ' -r --delete --force'
      local_dir = translate_to_rsync_path @local_dir
      remote_dir = translate_to_rsync_path @remote_dir
    end

    command = "#{@rsync_command} #{options} '#{local_dir}' '#{remote_dir}'"

    puts command

    IO.popen command do |output|
      puts output.read
    end
  end
end

# --- Execution ---

ever_sync = EverSync.new LOCAL_DIR, REMOTE_DIR, RSYNC_OPTIONS

ever_sync.rsync_command = RSYNC_COMMAND

if SIMULATE
  ever_sync.enable_simulation
end

ever_sync.start