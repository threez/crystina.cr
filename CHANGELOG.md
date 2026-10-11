# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Changed

- Bumped `ameba` dev dependency from `~> 1.6.0` to `~> 1.7.0`.
- Fixed violations surfaced by the ameba 1.7.0 upgrade (`Style/PercentLiteralDelimiters`,
  `Style/MultilineCurlyBlock`) in `spec/crystina_spec.cr` and `src/crystina/builder.cr`.
- Added an explicit `Ameba lint` step to the CI `lint` job and bumped the pinned
  Crystal version to `1.20.2`.
