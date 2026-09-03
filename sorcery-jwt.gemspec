lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "sorcery/jwt/version"

Gem::Specification.new do |spec|
  spec.name          = "sorcery-jwt"
  spec.version       = Sorcery::Jwt::VERSION
  spec.authors       = ["Hayden Luckenbach"]

  spec.summary       = "Jwt extension for the Sorcery authentication library"
  spec.description   = "Adds JWT issuance and authentication to the Sorcery " \
                        "authentication library, for API-only Rails apps."
  spec.homepage      = "https://github.com/hayfever/sorcery-jwt"
  spec.license       = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/CHANGELOG.md"

  spec.required_ruby_version = ">= 3.0"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been
  # added into git.
  spec.files = Dir.chdir(File.expand_path("..", __FILE__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      f.match(%r{^(test|spec|features)/})
    end
  end

  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"

  spec.add_runtime_dependency "jwt", ">= 1.0", "< 3.0"
  spec.add_runtime_dependency "sorcery", ">= 0.13", "< 0.17"
end