# EverSync: Cross-platform continuously syncing via rsync
#### zlib/libpng License. Copyright (c) 2012 James Koshigoe.


# Description
A simple cross-platform script to continuously monitor and and synchronize (one-way) a local directory's contents
with a remote resource using rsync. It uses the em-dir-watcher gem to be notified upon file changes. A practical
application for this (i.e. the reason I built it) might be for working on code locally and testing it on a remote
server (e.g. through a browser) everytime you make a change.

Note: The directory monitoring handler can't detect empty directories, so an empty file needs to be added to them
to pick them up.

# Installation
Install the em-dir-watcher gem and its dependencies (https://github.com/mockko/em-dir-watcher) and edit the
settings below.