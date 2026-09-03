# Changelog

## 0.2.1 (2026-09-03)

### Changed

- Supported sorcery range widened to `>= 0.16.5, < 0.19` (0.17 and 0.18
  verified). Previously pinned `< 0.17`, which blocked installs alongside
  current sorcery.
- CI now runs a matrix: Ruby 3.2–3.4 × sorcery 0.16.5 / 0.17 / 0.18.

## 0.2.0 (2026-09-03)

### Security

- **Fix auth bypass**: a validly-signed token without `id`/`email` claims hit
  `find_by({})`, which returns the first user in the table. `login_from_jwt`
  now rejects such tokens outright.
- `login_from_jwt` now requires the token's `email` claim to match the
  looked-up user's email.

### Fixed

- The model submodule now registers correctly on modern Rubies. The included
  hook called `sorcery_config.class_eval` on a Config *instance*, which was
  never a valid Ruby call; in applications, sorcery's `rescue NameError`
  silently skipped the submodule, leaving `issue_token`/`decode_token`
  undefined at runtime. The hook now uses `singleton_class.class_eval`.
- Removed an `include InstanceMethods` reference to a module that never
  existed (it resolved to sorcery's core `InstanceMethods` by accident).
- `token_valid?` no longer depends on ActiveSupport (`.present?`).
- Failed JWT authentication sets `@current_user` to `nil` (sorcery
  convention) instead of `false`.

### Added

- Spec suite covering issuance, decoding, expiry, tamper rejection (wrong
  secret/algorithm), the claim contract, and controller login paths.
- CI via GitHub Actions.

## 0.1.13 (2022-02-02)

- Last release of the original series.