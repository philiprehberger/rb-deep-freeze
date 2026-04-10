# frozen_string_literal: true

require_relative 'lib/philiprehberger/deep_freeze/version'

Gem::Specification.new do |spec|
  spec.name = 'philiprehberger-deep_freeze'
  spec.version = Philiprehberger::DeepFreeze::VERSION
  spec.authors = ['Philip Rehberger']
  spec.email = ['me@philiprehberger.com']

  spec.summary = 'Recursive deep freeze and deep dup with circular reference detection and key exclusion'
  spec.description = 'Recursively freeze entire object graphs (hashes, arrays, strings, structs, Data) ' \
                     'to create truly immutable data structures. Includes deep_dup, deep_frozen?, ' \
                     'deep_equal?, and deep_diff. Handles circular references and selective key exclusion.'
  spec.homepage = 'https://philiprehberger.com/open-source-packages/ruby/philiprehberger-deep_freeze'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.1.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/philiprehberger/rb-deep-freeze'
  spec.metadata['changelog_uri'] = 'https://github.com/philiprehberger/rb-deep-freeze/blob/main/CHANGELOG.md'
  spec.metadata['bug_tracker_uri'] = 'https://github.com/philiprehberger/rb-deep-freeze/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir['lib/**/*.rb', 'LICENSE', 'README.md', 'CHANGELOG.md']
  spec.require_paths = ['lib']
end
