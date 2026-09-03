module Sorcery
  module Controller
    module Submodules
      module Jwt
        def self.included(base)
          base.send(:include, InstanceMethods)
          Config.login_sources << :login_from_jwt
        end

        module InstanceMethods
          protected

          # A sorcery login source: authenticates the request from the
          # Authorization header when it carries a validly signed, unexpired
          # JWT whose id and email claims match a user.
          def login_from_jwt
            claims = decoded_token.first.slice("id", "email")
            return @current_user = nil if claims.empty?

            @current_user = user_class.find_by(claims)
            auto_login(@current_user) if @current_user
            @current_user
          rescue JWT::DecodeError, JWT::ExpiredSignature
            @current_user = nil
          end

          # Authenticates credentials via sorcery and, on success, issues a
          # JWT for the user carrying its id and email claims.
          #
          # @return [String, nil] the JWT, or nil when credentials fail
          def login_and_issue_token(*credentials)
            return unless (user = user_class.authenticate(*credentials))

            @current_user = user
            auto_login(@current_user)
            user_class.issue_token(id: @current_user.id, email: @current_user.email)
          end

          private

          def token
            return nil unless authorization_header

            authorization_header.split(" ").last
          end

          def authorization_header
            @authorization_header ||= request.headers["Authorization"]
          end

          def decoded_token
            user_class.decode_token(token)
          end
        end
      end
    end
  end
end
