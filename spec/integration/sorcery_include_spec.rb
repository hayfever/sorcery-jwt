# Integration: proves the jwt submodule survives sorcery's real include
# machinery (authenticates_with_sorcery! + include_required_submodules!).
# This is the path where failures are silently swallowed by sorcery's
# `rescue NameError` — the 9-year silent-skip bug this suite guards against.

require "active_record"

# activerecord pulls in railties, giving us the real Rails module (version,
# Engine) that sorcery's test helpers and engine expect at load time.
require "sorcery"
require "sorcery/jwt"

Sorcery::Controller::Config.submodules = [:jwt]
Sorcery::Controller::Config.user_config do |user|
  user.jwt_secret = "s3cr3t"
end

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")

RSpec.describe "sorcery integration" do
  it "wires the jwt submodule onto the model via authenticates_with_sorcery!" do
    user_class = Class.new(ActiveRecord::Base) do
      def self.table_name
        "users"
      end

      authenticates_with_sorcery!
    end

    expect(user_class.sorcery_config.jwt_secret).to eq("s3cr3t")

    token = user_class.issue_token(id: 1, email: "a@b.c")
    expect(user_class.token_valid?(token)).to be(true)
    expect(user_class.decode_token(token).first["id"]).to eq(1)
  end
end