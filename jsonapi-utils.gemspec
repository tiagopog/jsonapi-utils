# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'jsonapi/utils/version'

Gem::Specification.new do |spec|
  spec.name          = 'jsonapi-utils'
  spec.version       = JSONAPI::Utils::VERSION
  spec.authors       = ['Tiago Guedes', 'Douglas André']
  spec.email         = ['tiagopog@gmail.com', 'douglas@beautydate.com.br']

  spec.summary       = "JSON::Utils is a simple way to get a full-featured JSON API on your Rails application."
  spec.description   = "Build JSON API-compliant APIs on Rails with no (or less) learning curve."
  spec.homepage      = 'https://github.com/b2beauty/jsonapi-utils'
  spec.license       = 'MIT'

  spec.files         = Dir.glob('{bin,lib}/**/*') + %w(LICENSE.txt README.md CODE_OF_CONDUCT.md)
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'jsonapi-resources', '~> 0.9.0'

  spec.add_development_dependency 'bundler', '~> 1.10'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rails', ENV['RAILS_VERSION'] || '~> 5.1'
  spec.add_development_dependency 'sqlite3'
  spec.add_development_dependency 'rspec-rails', '~> 3.1'
  spec.add_development_dependency 'factory_girl', '~> 4.8'
  spec.add_development_dependency 'smart_rspec', '~> 0.1.6'
  spec.add_development_dependency 'pry', '~> 0.10.3'
  spec.add_development_dependency 'pry-byebug'
end
