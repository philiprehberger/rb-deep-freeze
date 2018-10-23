# philiprehberger-deep_freeze

[![Tests](https://github.com/philiprehberger/rb-deep-freeze/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-deep-freeze/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-deep_freeze.svg)](https://rubygems.org/gems/philiprehberger-deep_freeze)
[![License](https://img.shields.io/github/license/philiprehberger/rb-deep-freeze)](LICENSE)

Recursive deep freeze and deep dup with circular reference detection and key exclusion

## Requirements

- Ruby >= 3.1

## Installation

Add to your Gemfile:

```ruby
gem "philiprehberger-deep_freeze"
```

Or install directly:

```bash
gem install philiprehberger-deep_freeze
```

## Usage

```ruby
require 'philiprehberger/deep_freeze'

# Deep freeze an object
data = { users: [{ name: 'Alice', tags: ['admin'] }] }
Philiprehberger::DeepFreeze.freeze(data)
data[:users][0][:name].frozen? # => true

# Exclude certain keys from freezing
config = { cache: [], settings: { debug: true } }
Philiprehberger::DeepFreeze.freeze(config, except: [:cache])
config[:cache].frozen?    # => false
config[:settings].frozen? # => true

# Check if deeply frozen
Philiprehberger::DeepFreeze.frozen?(data) # => true

# Deep dup to get an unfrozen copy
copy = Philiprehberger::DeepFreeze.dup(data)
copy.frozen?                       # => false
copy[:users][0][:name].frozen?     # => false
```

## API

| Method | Description |
|--------|-------------|
| `DeepFreeze.freeze(obj, except: [])` | Recursively freeze an object and all nested objects; skips keys in `except` |
| `DeepFreeze.frozen?(obj)` | Return `true` if the object and all nested objects are frozen |
| `DeepFreeze.dup(obj)` | Recursively duplicate an object to create a fully unfrozen deep copy |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
