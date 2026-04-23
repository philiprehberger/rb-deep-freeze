# Changelog

All notable changes to this gem will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this gem adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.7.0] - 2026-04-23

### Added
- `DeepFreeze.deep_thaw(obj, except: [])` recursively unfreezes an object graph.
- `except:` now also accepts Struct member names in `deep_freeze` and `deep_frozen?`.
- YARD documentation on all public API methods.

### Changed
- `deep_dup` returns the original object for `Range` and `Regexp` values (both are immutable by design).

## [0.6.0] - 2026-04-15

### Added
- `DeepFreeze.deep_merge(a, b, &block)` to deeply merge two hashes, recursing into nested hashes; b's value wins on conflict (or the block resolves); returns a new frozen hash

## [0.5.0] - 2026-04-14

### Added
- `DeepFreeze.deep_freeze_all(*objects, except: [])` to freeze multiple objects with a shared visited-set for cross-object circular reference detection
- `DeepFreeze.deep_clone(obj)` to deep dup and deep freeze in one pass, returning a frozen deep copy
- `DeepFreeze.freeze_hash_keys(hash)` to recursively freeze only hash keys, leaving values mutable

## [0.4.0] - 2026-04-09

### Added
- `DeepFreeze.deep_diff(a, b)` returns a hash of path => `{ left:, right: }` pairs for every structural difference between two object graphs (Hash, Array, Struct, Data)

### Fixed
- Fix README to use correct method names (`deep_freeze`, `deep_frozen?`, `deep_dup`) instead of non-existent short aliases (`freeze`, `frozen?`, `dup`)

## [0.3.0] - 2026-04-09

### Added
- `DeepFreeze.deep_equal?` for structural equality comparison across Hash, Array, Set, Struct, and Data graphs regardless of frozen state

## [0.2.0] - 2026-04-04

### Added
- Ruby 3.2+ Data class support in `deep_freeze`, `deep_frozen?`, and `deep_dup`
- GitHub issue template gem version field
- Feature request "Alternatives considered" field

### Fixed
- Gemspec author and email to match standard template
- Gemspec `required_ruby_version` format consistency

## [0.1.11] - 2026-03-31

### Added
- Add GitHub issue templates, dependabot config, and PR template

## [0.1.10] - 2026-03-31

### Changed
- Standardize README badges, support section, and license format

## [0.1.9] - 2026-03-26

### Changed
- Add Sponsor badge to README
- Fix License section format


## [0.1.8] - 2026-03-24

### Changed
- Add Usage subsections to README for better feature discoverability

## [0.1.7] - 2026-03-24

### Fixed
- Standardize README code examples to use double-quote require statements

## [0.1.6] - 2026-03-24

### Fixed
- Standardize README API section to table format
- Fix Installation section quote style to double quotes

## [0.1.5] - 2026-03-23

### Fixed
- Standardize README to match template (installation order, code fences, license section, one-liner format)
- Update gemspec summary to match README description

## [0.1.4] - 2026-03-22

### Changed
- Fix README badges to match template (Tests, Gem Version, License)

## [0.1.3] - 2026-03-22

### Changed

- Expand test coverage to 30+ examples covering Struct freezing, empty collections, deeply nested structures, dup independence, Set duplication, and frozen primitive behavior

## [0.1.2] - 2026-03-22

### Fixed

- Fix CHANGELOG header wording
- Add bug_tracker_uri to gemspec

## [0.1.0] - 2026-03-22

### Added

- `DeepFreeze.freeze` to recursively freeze Hash, Array, String, Set, and Struct objects
- `DeepFreeze.frozen?` to check if an object and all nested objects are frozen
- `DeepFreeze.dup` to recursively dup and create unfrozen deep copies
- Circular reference detection to prevent infinite loops
- `except:` option to skip specified keys during freezing

[0.7.0]: https://github.com/philiprehberger/rb-deep-freeze/releases/tag/v0.7.0
[0.6.0]: https://github.com/philiprehberger/rb-deep-freeze/releases/tag/v0.6.0
[0.5.0]: https://github.com/philiprehberger/rb-deep-freeze/releases/tag/v0.5.0
[0.4.0]: https://github.com/philiprehberger/rb-deep-freeze/releases/tag/v0.4.0
[0.3.0]: https://github.com/philiprehberger/rb-deep-freeze/releases/tag/v0.3.0
[0.2.0]: https://github.com/philiprehberger/rb-deep-freeze/releases/tag/v0.2.0
[0.1.11]: https://github.com/philiprehberger/rb-deep-freeze/releases/tag/v0.1.11
[0.1.10]: https://github.com/philiprehberger/rb-deep-freeze/releases/tag/v0.1.10
[0.1.9]: https://github.com/philiprehberger/rb-deep-freeze/releases/tag/v0.1.9
[0.1.8]: https://github.com/philiprehberger/rb-deep-freeze/releases/tag/v0.1.8
[0.1.7]: https://github.com/philiprehberger/rb-deep-freeze/releases/tag/v0.1.7
[0.1.6]: https://github.com/philiprehberger/rb-deep-freeze/releases/tag/v0.1.6
[0.1.5]: https://github.com/philiprehberger/rb-deep-freeze/releases/tag/v0.1.5
[0.1.4]: https://github.com/philiprehberger/rb-deep-freeze/releases/tag/v0.1.4
[0.1.3]: https://github.com/philiprehberger/rb-deep-freeze/releases/tag/v0.1.3
[0.1.2]: https://github.com/philiprehberger/rb-deep-freeze/releases/tag/v0.1.2
[0.1.0]: https://github.com/philiprehberger/rb-deep-freeze/releases/tag/v0.1.0
