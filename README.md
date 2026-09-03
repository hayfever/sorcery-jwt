# Sorcery::Jwt

[![CI](https://github.com/hayfever/sorcery-jwt/actions/workflows/ci.yml/badge.svg)](https://github.com/hayfever/sorcery-jwt/actions)
[![Gem Version](https://badge.fury.io/rb/sorcery-jwt.svg)](https://rubygems.org/gems/sorcery-jwt)

Jwt extension for the [Sorcery](https://github.com/Sorcery/sorcery) authentication
library, for API-only Rails apps.

> **NOTE:** Sorcery v1 is being developed and JWT is planned as a core plugin.
> See https://github.com/Sorcery/sorcery-rework/issues/9. This gem targets the
> current (0.16–0.18) sorcery line.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "sorcery-jwt"
```

And then execute:

    $ bundle

## Usage

First, include the `:jwt` submodule in your list of configured Sorcery submodules:

```ruby
Rails.application.config.sorcery.submodules = [:jwt, ...]
```

Next, in the Sorcery `user_config`, set the secret and algorithm used to sign
tokens, the token lifetime in seconds, and (optionally) clock-skew tolerance:

```ruby
Rails.application.config.sorcery.configure do |config|
  # ...
  config.user_config do |user|
    user.jwt_secret     = Rails.application.secrets.secret_key_base
    user.jwt_algorithm  = "HS256"                  # default; see jwt/ruby-jwt for options
    user.session_expiry = 60 * 60 * 24 * 7 * 2      # default: 2 weeks (seconds)
    user.exp_leeway     = 30                        # optional; default nil = no leeway
  end
end
```

With the submodule included, each request checks the `Authorization` header
for a bearer JWT. If the token is validly signed, unexpired, and its claims
match a user, `current_user` is set. Handling invalid tokens (401s, etc.) is
up to your application.

To log a user in and issue a token:

```ruby
class SessionsController < ApplicationController
  def create
    token = login_and_issue_token(params[:email], params[:password])

    if token
      render json: { token: token }, status: :created
    else
      render json: { error: "invalid credentials" }, status: :unauthorized
    end
  end
end
```

### Claim contract

Tokens issued by `login_and_issue_token` carry the user's `id` and `email`,
plus the standard `exp` and `iat` claims. Authentication via
`login_from_jwt` requires **all** of the following, evaluated in one place:

1. a valid signature under the configured secret and algorithm
2. an unexpired `exp` (within `exp_leeway`, if configured)
3. `id` and `email` claims are present
4. the claims match an existing user

A validly-signed token that fails any check authenticates nobody — notably,
a token missing its identity claims can never fall through to an unfiltered
lookup.

### Token issuance API

You can also issue tokens directly from the user model:

```ruby
User.issue_token(id: user.id, email: user.email)  # => signed JWT string
User.decode_token(token)                           # => [payload, header]; raises JWT::DecodeError
User.token_valid?(token)                           # => boolean; never raises
```

## Security notes

- **No revocation is built in.** Tokens are valid until `exp`. If you need
  logout, invalidation on password change, or single-session enforcement, see
  [JWT revocation strategies](https://waiting-for-dev.github.io/blog/2017/01/24/jwt_revocation_strategies/)
  — any denylist/token-version approach can be layered on top by your app.
- The algorithm is pinned on decode: `alg: none` and key-confusion attacks
  are rejected.
- The signing secret should be at least as strong as `secret_key_base`
  rotated from your credentials store.

## Upgrading from 0.1.x

No API changes: `issue_token`, `decode_token`, `token_valid?`,
`login_and_issue_token`, and the `login_from_jwt` login source all behave as
before, and **tokens issued by 0.1.x remain valid** — no forced re-login.
Behavior fixes in the 0.2+ line:

- tokens with no `id`/`email` claims are rejected (previously authenticated
  the first user in the table)
- the `email` claim must match the looked-up user
- failed JWT login sets `current_user` to `nil` (sorcery convention)
- the model submodule actually registers on modern Rubies (see
  [CHANGELOG](CHANGELOG.md) — before 0.2, sorcery's `rescue NameError`
  could silently skip it, leaving `issue_token` undefined at runtime)

## Compatibility

Tested matrix (CI): Ruby 3.2 / 3.3 / 3.4 × sorcery 0.16.5 / 0.17 / 0.18.

## Contributing

Bug reports and pull requests are welcome at
https://github.com/hayfever/sorcery-jwt.

## License

The gem is available as open source under the terms of the
[MIT License](LICENSE.txt).