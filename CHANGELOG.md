# Changelog

All notable changes to this module are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- `invoke_log` input: creates an OCI Logging service log for the application
  (service `functions`, category `invoke`) in an existing log group, with
  `retention_days` (30-day steps, 30 to 180, default 30), an optional
  `display_name` (default `<display_name>_invoke`) and `is_enabled`. Off by
  default; new output `invoke_log_id` (null when off). Existing inputs and
  outputs are unchanged.

[Unreleased]: https://github.com/moveeeax/terraform-oci-functions/compare/v1.1.0...HEAD
