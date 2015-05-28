# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'acts_as_data_table/version'

Gem::Specification.new do |spec|
  spec.name          = "acts_as_data_table"
  spec.version       = ActsAsDataTable::VERSION
  spec.authors       = ["Stefan Exner"]
  spec.email         = ["stex@sterex.de"]
  spec.summary       = %q{Adds automatic scope based filtering and column sorting to controllers and models.}
  spec.description   = %q{Adds methods to models and controllers to perform automatic filtering, sorting and multi-column-queries without having to worry about the implementation.}
  spec.homepage      = 'https://www.github.com/stex/acts_as_data_table'
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"

  spec.add_dependency 'rails', '~> 4'
end
