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

### Thawing

Recursively unfreeze an object graph. Useful when you need a mutable copy of a
deeply frozen structure without re-building it. The `except:` option has the
opposite semantics of `deep_freeze`'s `except:` — values at the listed keys or
Struct member names are left frozen:

```ruby
original = { users: [{ name: "Alice" }], locked: "policy" }
Philiprehberger::DeepFreeze.deep_freeze(original)

thawed = Philiprehberger::DeepFreeze.deep_thaw(original)
thawed.frozen?                   # => false
thawed[:users][0][:name].frozen? # => false

# Keep specific branches frozen:
partial = Philiprehberger::DeepFreeze.deep_thaw(original, except: [:locked])
partial[:locked].frozen?          # => true
partial[:users][0][:name].frozen? # => false
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

### Batch Freezing

Freeze multiple objects at once, sharing a single visited-set for cross-object circular reference detection:

```ruby
config = { db: { host: "localhost" } }
cache = { store: config[:db] }

Philiprehberger::DeepFreeze.deep_freeze_all(config, cache)
config.frozen? # => true
cache.frozen?  # => true
```

### Deep Clone

Create a deeply frozen copy of an object without modifying the original:

```ruby
original = { users: [{ name: "Alice" }] }
clone = Philiprehberger::DeepFreeze.deep_clone(original)

clone.frozen?                     # => true
clone[:users][0][:name].frozen?   # => true
original.frozen?                  # => false
```

### Keys-Only Freeze

Recursively freeze only hash keys, leaving values mutable:

```ruby
schema = { "name" => "Alice", "tags" => ["admin"] }
Philiprehberger::DeepFreeze.freeze_hash_keys(schema)

schema.keys.first.frozen?  # => true
schema["name"].frozen?      # => false (value stays mutable)
```

### Deep Merge

Deeply merge two hashes, recursing into nested hashes. When both values for a key are hashes, it recurses. Otherwise, the second hash's value wins (or a block resolves conflicts). Returns a new frozen hash:

```ruby
a = { db: { host: "localhost", port: 5432 }, debug: false }
b = { db: { port: 3306, name: "app" }, debug: true }

result = Philiprehberger::DeepFreeze.deep_merge(a, b)
# => { db: { host: "localhost", port: 3306, name: "app" }, debug: true }
result.frozen? # => true
```

With a block for conflict resolution:

```ruby
a = { score: 10, name: "Alice" }
b = { score: 5, name: "Bob" }

Philiprehberger::DeepFreeze.deep_merge(a, b) { |_key, old_val, new_val| old_val + new_val }
# => { score: 15, name: "AliceBob" }
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
| `DeepFreeze.deep_freeze(obj, except: [])` | Recursively freeze an object and all nested objects (Hash, Array, Set, Struct, Data); `except` skips Hash keys and Struct member names |
| `DeepFreeze.deep_freeze_all(*objects, except: [])` | Freeze multiple objects sharing one visited-set for cross-object circular reference detection |
| `DeepFreeze.deep_clone(obj, except: [])` | Deep dup + deep freeze in one pass — returns a frozen deep copy without modifying the original |
| `DeepFreeze.freeze_hash_keys(hash)` | Recursively freeze only hash keys, leaving values mutable |
| `DeepFreeze.deep_frozen?(obj, except: [])` | Return `true` if the object and all nested objects (including Struct and Data members) are frozen; `except` ignores Hash keys and Struct members |
| `DeepFreeze.deep_dup(obj)` | Recursively duplicate an object to create a fully unfrozen deep copy (supports Struct and Data); returns `Range`/`Regexp` values as-is |
| `DeepFreeze.deep_thaw(obj, except: [])` | Recursively unfreeze an object graph; `except` leaves specified Hash keys / Struct members frozen (opposite of `deep_freeze`) |
| `DeepFreeze.deep_merge(a, b, &block)` | Deeply merge two hashes, recursing into nested hashes; b wins conflicts (or block resolves); returns a new frozen hash |
| `DeepFreeze.deep_equal?(a, b)` | Structural equality across nested Hash, Array, Set, Struct, and Data — ignores frozen state |
| `DeepFreeze.deep_diff(a, b)` | Return a hash of path => `{ left:, right: }` pairs for every structural difference |

### Struct `except:` example

`except:` in `deep_freeze` and `deep_frozen?` also accepts Struct member names:

```ruby
Config = Struct.new(:host, :cache)
cfg = Config.new("localhost", +"mutable_cache")
Philiprehberger::DeepFreeze.deep_freeze(cfg, except: [:cache])

cfg.frozen?        # => true
cfg.cache.frozen?  # => false
Philiprehberger::DeepFreeze.deep_frozen?(cfg, except: [:cache]) # => true
```

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
