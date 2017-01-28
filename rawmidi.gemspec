# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rawmidi/version'

Gem::Specification.new do |spec|
  spec.name          = "rawmidi"
  spec.version       = RawMIDI::VERSION
  spec.authors       = ["Damián Silvani"]
  spec.email         = ["munshkr@gmail.com"]

  spec.summary       = %q{Ruby FFI binding for ALSA RawMIDI}
  spec.homepage      = "https://github.com/munshkr/rawmidi-rb"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features|playground)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.13"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency 'pry'

  spec.add_dependency 'ffi'
end
