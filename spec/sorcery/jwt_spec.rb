# PORO test doubles — no Rails/dummy app needed.
# JwtTestUser mimics ActiveRecord semantics: find_by({}) returns the first row
# (the auth-bypass hole the guard in login_from_jwt must close).

class JwtTestUser
  def self.sorcery_config
    @sorcery_config ||= Sorcery::Model::Config.new
  end

  include Sorcery::Model::Submodules::Jwt

  USERS = { 1 => "a@b.c" }.freeze

  attr_reader :id, :email

  def initialize(id, email)
    @id = id
    @email = email
  end

  def self.find_by(claims)
    return new(*USERS.first) if claims.empty? # AR: find_by({}) == first row

    email = claims["email"]
    return nil unless claims["id"] && USERS[claims["id"]] == email

    new(claims["id"], email)
  end

  def self.authenticate(email, password)
    return nil unless password == "secret" && email == "a@b.c"

    new(1, "a@b.c")
  end
end

class JwtTestController
  include Sorcery::Controller::Submodules::Jwt

  attr_accessor :current_user
  attr_reader :auto_login_user

  def initialize(headers = {})
    @request = Struct.new(:headers).new(headers)
  end

  def user_class
    JwtTestUser
  end

  def request
    @request
  end

  def auto_login(user)
    @auto_login_user = user
  end

  def login_from_jwt!
    send(:login_from_jwt)
  end
end

RSpec.describe Sorcery::Jwt do
  let(:plain_controller) { JwtTestController.new({}) }

  before do
    JwtTestUser.sorcery_config.jwt_secret = "s3cr3t"
    JwtTestUser.sorcery_config.session_expiry = 3600
  end

  def controller_for(payload)
    JwtTestController.new("Authorization" => "Bearer #{JwtTestUser.issue_token(payload)}")
  end

  describe ".issue_token / .decode_token" do
    it "round-trips the payload and sets exp" do
      token = JwtTestUser.issue_token(id: 1, email: "a@b.c")
      payload, = JwtTestUser.decode_token(token)

      expect(payload["id"]).to eq(1)
      expect(payload["email"]).to eq("a@b.c")
      expect(payload["exp"]).to be > Time.now.to_i
    end

    it "rejects a wrong-secret token" do
      forged = JWT.encode({ "id" => 1 }, "other-secret", "HS256")

      expect { JwtTestUser.decode_token(forged) }.to raise_error(JWT::DecodeError)
    end

    it "rejects a wrong-algorithm token" do
      forged = JWT.encode({ "id" => 1 }, "s3cr3t", "HS512")

      expect { JwtTestUser.decode_token(forged) }.to raise_error(JWT::DecodeError)
    end

    it "respects a configured algorithm" do
      JwtTestUser.sorcery_config.jwt_algorithm = "HS512"
      token = JwtTestUser.issue_token(id: 1, email: "a@b.c")

      expect(JwtTestUser.decode_token(token).first["id"]).to eq(1)
    end
  end

  describe "config defaults" do
    it "defaults jwt_algorithm to HS256 and session_expiry to two weeks" do
      fresh = Class.new do
        def self.sorcery_config
          @sorcery_config ||= Sorcery::Model::Config.new
        end
      end
      fresh.include(Sorcery::Model::Submodules::Jwt)

      expect(fresh.sorcery_config.jwt_algorithm).to eq("HS256")
      expect(fresh.sorcery_config.session_expiry).to eq(60 * 60 * 24 * 7 * 2)
    end
  end

  describe ".token_valid?" do
    it "is true for a valid token and false for invalid ones" do
      expect(JwtTestUser.token_valid?(JwtTestUser.issue_token(id: 1, email: "a@b.c"))).to be(true)
      expect(JwtTestUser.token_valid?("garbage")).to be(false)
      expect(JwtTestUser.token_valid?(nil)).to be(false)
    end

    it "is false for an expired token" do
      JwtTestUser.sorcery_config.session_expiry = -10

      expect(JwtTestUser.token_valid?(JwtTestUser.issue_token(id: 1, email: "a@b.c"))).to be(false)
    end
  end

  describe "#login_from_jwt" do
    it "logs in from a valid Authorization header" do
      controller = controller_for(id: 1, email: "a@b.c")

      expect(controller.login_from_jwt!.id).to eq(1)
      expect(controller.auto_login_user).to eq(controller.current_user)
    end

    it "does not log in when the token has no identity claims" do
      # Regression: validly-signed token with no id/email previously hit
      # find_by({}), which returns the first user — an auth bypass.
      controller = controller_for({})

      expect(controller.login_from_jwt!).to be_nil
      expect(controller.current_user).to be_nil
    end

    it "does not log in for an expired token" do
      JwtTestUser.sorcery_config.session_expiry = -10
      controller = controller_for(id: 1, email: "a@b.c")

      expect(controller.login_from_jwt!).to be_nil
      expect(controller.current_user).to be_nil
    end

    it "does not log in for an unknown subject" do
      controller = controller_for(id: 999, email: "nobody@nowhere.dev")

      expect(controller.login_from_jwt!).to be_nil
    end

    it "does not log in when the email claim does not match the user" do
      controller = controller_for(id: 1, email: "impostor@evil.dev")

      expect(controller.login_from_jwt!).to be_nil
    end

    it "does not log in for a malformed token in the header" do
      controller = JwtTestController.new("Authorization" => "Bearer not.a.jwt")

      expect(controller.login_from_jwt!).to be_nil
      expect(controller.current_user).to be_nil
    end

    it "does not log in with no Authorization header" do
      expect(plain_controller.login_from_jwt!).to be_nil
      expect(plain_controller.current_user).to be_nil
    end
  end

  describe "#login_and_issue_token" do
    it "issues a decodable token for valid credentials" do
      token = plain_controller.send(:login_and_issue_token, "a@b.c", "secret")

      expect(JwtTestUser.token_valid?(token)).to be(true)
      expect(plain_controller.current_user.id).to eq(1)
      expect(plain_controller.auto_login_user).to eq(plain_controller.current_user)
    end

    it "returns nil for bad credentials" do
      expect(plain_controller.send(:login_and_issue_token, "a@b.c", "wrong")).to be_nil
      expect(plain_controller.current_user).to be_nil
      expect(plain_controller.auto_login_user).to be_nil
    end
  end

  describe "secret validation" do
    it "raises when no secret is configured" do
      JwtTestUser.sorcery_config.jwt_secret = nil

      expect { JwtTestUser.send(:validate_secret_defined) }
        .to raise_error(ArgumentError, /secret must be configured/)
    end
  end
end