Gem::Specification.new do |spec|
  spec.name          = 'lita-metrics'
  spec.version       = '0.1.1'
  spec.authors       = ['Tristan Chong']
  spec.email         = ['tristan@pagerduty.com']
  spec.description   = 'A Lita handler that tracks Lita usage metrics.'
  spec.summary       = spec.description
  spec.homepage      = 'https://github.com/PagerDuty/lita-metrics'
  spec.license       = 'MIT'
  spec.metadata      = { 'lita_plugin_type' => 'handler' }

  spec.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'lita', '>= 4.6'
  spec.add_runtime_dependency 'dogstatsd-ruby', '~> 1.5.0'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rack-test'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'coveralls'
  spec.add_development_dependency 'rubocop'
end
