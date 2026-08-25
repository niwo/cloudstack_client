# Changelog

## 2.0.0 - 2026-08-25

- Require Ruby 3.0 or newer.
- Enable HTTPS certificate verification by default, with optional custom CA
  certificate support.
- Use safe YAML loading for configuration files.
- Fix request dispatch when no custom host is configured.
- Support CloudStack command names containing acronyms, such as
  `create_ssh_key_pair`.
- Improve error handling for malformed API definitions and asynchronous job
  failures.
