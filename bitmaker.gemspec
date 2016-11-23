# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bitmaker/version'

Gem::Specification.new do |spec|
  spec.name          = "bitmaker"
  spec.version       = Bitmaker::VERSION
  spec.authors       = ["Mina Mikhail"]
  spec.email         = ["mina@bitmaker.co"]

  spec.summary       = %q{A Ruby wrapper for the Bitmaker API}
  spec.homepage      = "https://github.com/bitmakerlabs/bitmaker-ruby"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "jwt", "~> 1.5"
  spec.add_dependency "multi_json", "~> 1.12"

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency 'activesupport', "~> 5.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "minitest-reporters", "~> 1.1"
  spec.add_development_dependency "webmock", "~> 2.1"
  spec.add_development_dependency "timecop", "~> 0.8"
end
