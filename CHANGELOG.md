# Changelog

All notable changes to this gem will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this gem adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
n## [0.1.4] - 2026-03-22

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

[0.1.0]: https://github.com/philiprehberger/rb-deep-freeze/releases/tag/v0.1.0
