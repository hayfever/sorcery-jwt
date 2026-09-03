require "sorcery/jwt/version"
require "jwt"

module Sorcery
  module Model
    module Submodules
      module Jwt
        def self.included(base)
          # Define the jwt accessors on the config instance's singleton class;
          # Config#class_eval is not a valid Ruby call.
          base.sorcery_config.singleton_class.class_eval do
            # Secret used to encode JWTs. Should correspond to the type needed by the algorithm used.
            attr_accessor :jwt_secret
            # Type of the algorithm used to encode JWTs. Corresponds to the options available in jwt/ruby-jwt.
            attr_accessor :jwt_algorithm
            # How long the session should be valid for in seconds. Will be set as the exp claim in the token.
            attr_accessor :session_expiry
            # Clock-skew tolerance in seconds applied when verifying exp. nil disables leeway.
            attr_accessor :exp_leeway
          end

          base.sorcery_config.instance_eval do
            @defaults[:@jwt_algorithm] = "HS256"
            @defaults[:@session_expiry] = 60 * 60 * 24 * 7 * 2 # 2 weeks
            @defaults[:@exp_leeway] = nil

            reset!
          end

          base.sorcery_config.after_config << :validate_secret_defined

          base.extend(ClassMethods)
        end

        module ClassMethods
          # Encodes a JWT for a user, adding the exp and iat claims.
          # Any claim in the payload except exp and iat is preserved.
          #
          # @param payload [Hash] claims to encode; must include "id" and "email"
          #   for the token to authenticate via the controller submodule
          # @return [String] the signed JWT
          def issue_token(payload)
            now = Time.now.to_i
            exp_payload = payload.merge(iat: now, exp: now + @sorcery_config.session_expiry)
            JWT.encode(exp_payload, @sorcery_config.jwt_secret, @sorcery_config.jwt_algorithm)
          end

          # Decodes and verifies a JWT with the configured secret and algorithm.
          #
          # @param token [String, nil] the JWT
          # @return [Array<(Hash, Hash)>] payload and header, as returned by jwt
          # @raise [JWT::DecodeError] if the signature, algorithm, or exp fail
          def decode_token(token)
            options = { algorithm: @sorcery_config.jwt_algorithm }
            options[:exp_leeway] = @sorcery_config.exp_leeway if @sorcery_config.exp_leeway
            JWT.decode(token, @sorcery_config.jwt_secret, true, options)
          end

          # Returns whether a JWT is validly signed and unexpired.
          #
          # @param token [String, nil]
          # @return [Boolean]
          def token_valid?(token)
            !!decode_token(token)
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
