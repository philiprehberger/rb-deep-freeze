# Changelog

All notable changes to this gem will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this gem adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[0.1.0]: https://github.com/philiprehberger/rb-deep-freeze/releases/tag/v0.1.0
