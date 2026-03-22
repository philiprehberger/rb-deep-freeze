# Changelog

All notable changes to this gem will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this gem adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-03-21

### Added
- Initial release
- Recursive deep freeze for hashes, arrays, sets, strings, and structs
- Deep frozen check with `DeepFreeze.frozen?`
- Deep unfrozen copy with `DeepFreeze.dup`
- Circular reference handling
- Selective exclusion via `except:` parameter
