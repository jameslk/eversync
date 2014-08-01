# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'eversync/version'

Gem::Specification.new do |spec|
  spec.name          = "eversync"
  spec.version       = Eversync::VERSION
  spec.authors       = ["James Koshigoe"]
  spec.email         = ["james@jameskoshigoe.com"]
  spec.summary       = %q{Continuous syncing with rsync}
  spec.description   = %q{A simple tool to continuously monitor and and synchronize (one-way) a local directory's contents with a remote resource using rsync.}
  spec.homepage      = "https://github.com/jameslk/eversync"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  gem.executables   = ["eversync"]
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
end
