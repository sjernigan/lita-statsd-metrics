Gem::Specification.new do |spec|
  spec.name          = "lita-metrics"
  spec.version       = "0.1.0"
  spec.authors       = ["Tristan Chong"]
  spec.email         = ["tristan@pagerduty.com"]
  spec.description   = "A Lita handler that tracks Lita usage metrics."
  spec.summary       = "A Lita handler that tracks Lita usage metrics."
  spec.homepage      = "https://github.com/PagerDuty/lita-metrics"
  spec.license       = "MIT"
  spec.metadata      = { "lita_plugin_type" => "handler" }

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "lita", ">= 4.5"
  spec.add_runtime_dependency "dogstatsd-ruby", "~> 1.5.0"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rack-test"
  spec.add_development_dependency "rspec", ">= 3.0.0"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "coveralls"
  spec.add_development_dependency 'rubocop'
end
