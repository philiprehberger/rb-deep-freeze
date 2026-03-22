# philiprehberger-deep_freeze

[![Tests](https://github.com/philiprehberger/rb-deep-freeze/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-deep-freeze/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-deep_freeze.svg)](https://rubygems.org/gems/philiprehberger-deep_freeze)
[![License](https://img.shields.io/github/license/philiprehberger/rb-deep-freeze)](LICENSE)

Recursive deep freeze and deep dup for Ruby objects

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
require "philiprehberger/deep_freeze"

data = { a: { b: "hello" }, list: ["x", "y"] }
frozen = Philiprehberger::DeepFreeze.freeze(data)
frozen[:a][:b].frozen?  # => true
```

### Selective Exclusion

```ruby
data = { config: "mutable", payload: "frozen" }
result = Philiprehberger::DeepFreeze.freeze(data, except: [:config])
result[:config].frozen?   # => false
result[:payload].frozen?  # => true
```

### Deep Frozen Check

```ruby
Philiprehberger::DeepFreeze.frozen?(frozen)  # => true

shallow = { a: { b: "c" } }
shallow.freeze
Philiprehberger::DeepFreeze.frozen?(shallow)  # => false
```

### Deep Dup

```ruby
thawed = Philiprehberger::DeepFreeze.dup(frozen)
thawed[:a][:b].frozen?  # => false
```

## API

| Method | Description |
|--------|-------------|
| `DeepFreeze.freeze(obj, except: [])` | Recursively freeze an object graph |
| `DeepFreeze.frozen?(obj)` | Check if an object graph is deeply frozen |
| `DeepFreeze.dup(obj)` | Create a deep unfrozen copy |

## Development

```bash
bundle install
bundle exec rspec      # Run tests
bundle exec rubocop    # Check code style
```

## License

MIT
