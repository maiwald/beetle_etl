# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'beetle_etl/version'

Gem::Specification.new do |spec|
  spec.name          = 'beetle_etl'
  spec.version       = BeetleETL::VERSION
  spec.authors       = ['Luciano Maiwald']
  spec.email         = ['luciano.maiwald@gmail.com']
  spec.summary       = %q{BeetleETL helps you with your recurring ETL imports.}
  spec.description   = %q{Taking care of synchronizing external data with referential data in your application.}
  spec.homepage      = 'https://github.com/maiwald/beetle_etl'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'sequel', '>= 4.0.0'
  spec.add_runtime_dependency 'activesupport', '>= 4.2.0'

  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'rspec', '>= 3.0.0'
  spec.add_development_dependency 'timecop', '>= 0.7.0'
  spec.add_development_dependency 'pg', '>= 0.18.0'
  spec.add_development_dependency 'unindent', '~> 1.0'
end
