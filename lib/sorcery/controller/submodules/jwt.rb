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

          def login_from_jwt
            user = decoded_token.first.slice("id", "email")

            @current_user = user_class.find_by(user)
            auto_login(@current_user) if @current_user
            @current_user
          rescue JWT::DecodeError, JWT::ExpiredSignature
            @current_user = false
          end

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
            @authorization_header ||= request.headers[@sorcery_config.jwt_header]
          end

          def decoded_token
            user_class.decode_token(token)
          end
        end
      end
    end
  end
end
