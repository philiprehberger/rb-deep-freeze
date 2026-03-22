# frozen_string_literal: true

require_relative 'lib/philiprehberger/deep_freeze/version'

Gem::Specification.new do |spec|
  spec.name = 'philiprehberger-deep_freeze'
  spec.version = Philiprehberger::DeepFreeze::VERSION
  spec.authors = ['philiprehberger']
  spec.email = ['philiprehberger@users.noreply.github.com']

  spec.summary = 'Recursive deep freeze and deep dup for Ruby objects'
  spec.description = 'Recursively freeze entire object graphs (hashes, arrays, strings, structs) ' \
                     'to create truly immutable data structures. Handles circular references ' \
                     'and supports selective exclusion.'
  spec.homepage = 'https://github.com/philiprehberger/rb-deep-freeze'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.1'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata['bug_tracker_uri'] = "#{spec.homepage}/issues"
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir['lib/**/*.rb', 'LICENSE', 'README.md', 'CHANGELOG.md']
  spec.require_paths = ['lib']
end
