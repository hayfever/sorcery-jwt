# Sorcery::Jwt

Jwt extension for the Sorcery authentication library

# NOTE: Sorcery v1 is being developed and JWT is being implemented as a core plugin. See https://github.com/Sorcery/sorcery-rework/issues/9 for more.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sorcery-jwt'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sorcery-jwt

## Usage

First, include the `:jwt` submodule in your list of configured Sorcery submodules:

```
Rails.application.config.sorcery.submodules = [:jwt, ...]
```

Next, in the Sorcery `user_config`, set the secret and algorithm that will be used to sign your tokens. You can also set length of time in seconds that the token will be valid for. Note that this is configured separately from the `:session_timeout` submodule.

```
Rails.application.config.sorcery.configure do |config|
  # ...
  config.user_config do |user|
    # ...
    user.jwt_secret = Rails.application.secrets.secret_key_base
    user.jwt_algorithm = "HS256" # HS256 is used by default.
    user.session_expiry = 60 * 60 * 24 * 7 * 2 # 2 weeks is used by default.
  end
end
```

Available algorithms are listed at https://github.com/jwt/ruby-jwt.

You're now ready to start using the library. By including the submodule, each request will check for an authorization header with a JWT as the value. If the JWT is valid, it will set the `current_user` in the controller to the matching user. It is up to you to handle what happens when a token is invalid or JWTs need to be revoked. Some ideas here: http://waiting-for-dev.github.io/blog/2017/01/24/jwt_revocation_strategies.

To login a user and issue a token, use the `login_and_issue_token` method from a controller. This method takes the same `email` and `password` arguments that the Sorcery `authenticate` method does.

Example:

```
def login
  token = login_and_issue_token(params[:email], params[:password])

  render json: {
    user: serialize(current_user),
    token: token
  }
end
```

By using `login_and_issue_token` with valid credentials, you're also setting `current_user` in your controller.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/hayfever/sorcery-jwt. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Sorcery::Jwt project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/hayfever/sorcery-jwt/blob/master/CODE_OF_CONDUCT.md).
