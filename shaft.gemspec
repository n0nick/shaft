# -*- encoding: utf-8 -*-
require File.expand_path('../lib/shaft/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Sagie Maoz"]
  gem.email         = ["sagie2maoz.info"]
  gem.description   = %q{SSH tunnels manager}
  gem.summary       = %q{An SSH tunnel assistant for the command line.}
  gem.homepage      = "http://github.com/n0nick/shaft"

  gem.add_dependency "thor"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "shaft"
  gem.require_paths = ["lib"]
  gem.version       = Shaft::VERSION
end
