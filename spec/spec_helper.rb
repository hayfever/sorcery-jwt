require "bundler/setup"

# Minimal Rails stub: sorcery 0.16.5 Model::Config#initialize calls Rails.version unguarded
module Rails
  def self.version
    "7.0.0"
  end
end

Dir[File.join(Gem.loaded_specs["sorcery"].full_gem_path, "lib/sorcery/crypto_providers/*.rb")].sort.each { require _1 }
require "sorcery/model/config"   # PORO harness: sorcery root requires Rails
require "sorcery/controller/config"
require "sorcery/jwt"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
