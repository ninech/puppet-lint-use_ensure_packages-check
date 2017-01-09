Gem::Specification.new do |spec|
  spec.name        = 'puppet-lint-use_ensure_packages-check'
  spec.version     = '0.0.1'
  spec.homepage    = 'https://github.com/ninech/puppet-lint-use_ensure_packages-check'
  spec.license     = 'MIT'
  spec.author      = 'Marius Rieder'
  spec.email       = 'marius.rieder@nine.ch'
  spec.files       = Dir[
    'README.md',
    'LICENSE',
    'lib/**/*',
    'spec/**/*',
  ]
  spec.test_files  = Dir['spec/**/*']
  spec.summary     = 'A puppet-lint plugin to check where ensure_packages should be used.'
  spec.description = <<-EOF
    A puppet-lint plugin to check that contains if ! defined (Package statements.
  EOF

  spec.add_dependency             'puppet-lint', '~> 2.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rspec-its', '~> 1.0'
  spec.add_development_dependency 'rspec-collection_matchers', '~> 1.0'
  spec.add_development_dependency 'rspec-json_expectations'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rubocop'
end
