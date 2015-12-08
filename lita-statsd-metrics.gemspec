Gem::Specification.new do |spec|
  spec.name          = 'lita-statsd-metrics'
  spec.version       = '0.1'
  spec.authors       = ['Steve Jernigan','Tristan Chong']
  spec.email         = ['steve.jernigan@gmail.com']
  spec.description   = 'A Lita handler that tracks Lita usage metrics in statsd.'
  spec.summary       = spec.description
  spec.homepage      = 'https://github.com/sjernigan/lita-statsd-metrics'
  spec.license       = 'MIT'
  spec.metadata      = { 'lita_plugin_type' => 'handler' }

  spec.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'lita', '>= 4.6'
  spec.add_runtime_dependency 'statsd-ruby', '~> 1.2.1'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rack-test'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'coveralls'
  spec.add_development_dependency 'rubocop'
end
