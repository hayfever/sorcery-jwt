require "sorcery/jwt/version"
require "jwt"

module Sorcery
  module Model
    module Submodules
      module Jwt
        def self.included(base)
          base.sorcery_config.class_eval do
            # Secret used to encode JWTs. Should correspond to the type needed by the algorithm used.
            attr_accessor :jwt_secret
            # Type of the algorithm used to encode JWTs. Corresponds to the options available in jwt/ruby-jwt.
            attr_accessor :jwt_algorithm
            # How long the session should be valid for in seconds. Will be set as the exp claim in the token.
            attr_accessor :session_expiry
          end

          base.sorcery_config.instance_eval do
            @defaults[:@jwt_algorithm] = "HS256"
            @defaults[:@session_expiry] = Time.now.to_i + (3600 * 24 * 14)

            reset!
          end

          base.sorcery_config.after_config << :validate_secret_defined

          base.extend(ClassMethods)
          base.send(:include, InstanceMethods)
        end

        module ClassMethods
          def issue_token(payload)
            exp_payload = payload.merge(exp: @sorcery_config.session_expiry)
            JWT.encode(exp_payload, @sorcery_config.jwt_secret, @sorcery_config.jwt_algorithm)
          end

          def decode_token(token)
            JWT.decode(token, @sorcery_config.jwt_secret, true, algorithm: @sorcery_config.jwt_algorithm)
          end

          def token_valid?(token)
            decode_token(token).present?
          rescue JWT::DecodeError, JWT::ExpiredSignature
            false
          end

          protected

          def validate_secret_defined
            message = "A secret must be configured when using the Sorcery::Jwt extension."
            raise ArgumentError, message if @sorcery_config.jwt_secret.nil?
          end
        end
      end
    end
  end
end
