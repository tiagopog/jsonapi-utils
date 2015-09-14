# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'jsonapi/utils/version'

Gem::Specification.new do |spec|
  spec.name          = "jsonapi-utils"
  spec.version       = JSONAPI::Utils::VERSION
  spec.authors       = ["Tiago Guedes", "Douglas André"]
  spec.email         = ["tiagopog@gmail.com", "douglas@beautydate.com.br"]

  spec.summary       = %q{Full-featured JSON API serialization in a simple way}
  spec.description   = %q{A Rails-way to get your API's data serialized following the JSON API's specs (http://jsosapi.org)}
  spec.homepage      = "https://github.com/b2beauty/jsonapi-utils"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
end
