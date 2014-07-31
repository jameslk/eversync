# EverSync: Cross-platform continuously syncing via rsync

# Description
A simple cross-platform script to continuously monitor and and synchronize (one-way) a local directory's contents with
a remote resource using rsync. It depends on a gem called [listen](https://github.com/guard/listen) to be notified upon
file changes. A practical application for this (i.e. the reason I built it) might be for working on code locally and
testing it on a remote server (e.g. through a browser) everytime you make a change.

Note: The directory monitoring handler can't detect empty directories, so an empty file needs to be added to them to
pick them up.

# Installation
Install the listen gem and its dependencies (https://github.com/guard/listen) and edit the settings at the top of the
script file.
