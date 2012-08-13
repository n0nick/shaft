# -*- encoding: utf-8 -*-
require File.expand_path('../lib/shaft/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Sagie Maoz"]
  gem.email         = ["sagie2maoz.info"]
  gem.description   = %q{SSH tunnels manager}
  gem.summary       = %q{Assists in starting and stopping SSH tunnel connections}
  gem.homepage      = ""

  gem.add_dependency "thor"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "shaft"
  gem.require_paths = ["lib"]
  gem.version       = Shaft::VERSION
end
