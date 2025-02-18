# philiprehberger-deep_freeze

[![Tests](https://github.com/philiprehberger/rb-deep-freeze/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-deep-freeze/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-deep_freeze.svg)](https://rubygems.org/gems/philiprehberger-deep_freeze)
[![Last updated](https://img.shields.io/github/last-commit/philiprehberger/rb-deep-freeze)](https://github.com/philiprehberger/rb-deep-freeze/commits/main)

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
require "philiprehberger/deep_freeze"

data = { users: [{ name: "Alice", tags: ["admin"] }] }
Philiprehberger::DeepFreeze.deep_freeze(data)
data[:users][0][:name].frozen? # => true
```

### Key Exclusion

Skip specific hash keys from being frozen with the `except:` option:

```ruby
config = { cache: [], settings: { debug: true } }
Philiprehberger::DeepFreeze.deep_freeze(config, except: [:cache])
config[:cache].frozen?    # => false
config[:settings].frozen? # => true
```

### Checking Frozen State

Verify that an object and all of its nested children are frozen:

```ruby
data = { users: [{ name: "Alice" }] }
Philiprehberger::DeepFreeze.deep_freeze(data)
Philiprehberger::DeepFreeze.deep_frozen?(data) # => true

partial = { list: ["a", "b"] }
partial.freeze
Philiprehberger::DeepFreeze.deep_frozen?(partial) # => false (nested strings are not frozen)
```

### Deep Dup

Create a fully unfrozen deep copy of a frozen object:

```ruby
original = { users: [{ name: "Alice" }] }
Philiprehberger::DeepFreeze.deep_freeze(original)

copy = Philiprehberger::DeepFreeze.deep_dup(original)
copy.frozen?                   # => false
copy[:users][0][:name].frozen? # => false
```

### Data Class Support (Ruby 3.2+)

```ruby
require "philiprehberger/deep_freeze"

Point = Data.define(:x, :y)
point = Point.new(x: "origin", y: [1, 2])

frozen_point = Philiprehberger::DeepFreeze.deep_freeze(point)
frozen_point.x.frozen?  # => true
frozen_point.y.frozen?  # => true
```

### Structural Equality

Compare two object graphs without caring about frozen state or object identity:

```ruby
original = { users: [{ name: "Alice", tags: ["admin"] }] }
Philiprehberger::DeepFreeze.deep_freeze(original)

copy = Philiprehberger::DeepFreeze.deep_dup(original)
Philiprehberger::DeepFreeze.deep_equal?(original, copy) # => true
```

### Structural Diff

Find exactly where two object graphs differ:

```ruby
a = { users: [{ name: "Alice", age: 30 }] }
b = { users: [{ name: "Bob", age: 30 }] }

Philiprehberger::DeepFreeze.deep_diff(a, b)
# => { [:users, 0, :name] => { left: "Alice", right: "Bob" } }
```

Returns `{}` when the objects are structurally equal.

## API

| Method | Description |
|--------|-------------|
| `DeepFreeze.deep_freeze(obj, except: [])` | Recursively freeze an object and all nested objects (Hash, Array, Set, Struct, Data); skips keys in `except` |
| `DeepFreeze.deep_frozen?(obj)` | Return `true` if the object and all nested objects (including Struct and Data members) are frozen |
| `DeepFreeze.deep_dup(obj)` | Recursively duplicate an object to create a fully unfrozen deep copy (supports Struct and Data) |
| `DeepFreeze.deep_equal?(a, b)` | Structural equality across nested Hash, Array, Set, Struct, and Data — ignores frozen state |
| `DeepFreeze.deep_diff(a, b)` | Return a hash of path => `{ left:, right: }` pairs for every structural difference |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## Support

If you find this project useful:

⭐ [Star the repo](https://github.com/philiprehberger/rb-deep-freeze)

🐛 [Report issues](https://github.com/philiprehberger/rb-deep-freeze/issues?q=is%3Aissue+is%3Aopen+label%3Abug)

💡 [Suggest features](https://github.com/philiprehberger/rb-deep-freeze/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement)

❤️ [Sponsor development](https://github.com/sponsors/philiprehberger)

🌐 [All Open Source Projects](https://philiprehberger.com/open-source-packages)

💻 [GitHub Profile](https://github.com/philiprehberger)

🔗 [LinkedIn Profile](https://www.linkedin.com/in/philiprehberger)

## License

[MIT](LICENSE)
