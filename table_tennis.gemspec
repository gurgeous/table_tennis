require_relative "lib/table_tennis/version"

Gem::Specification.new do |s|
  s.name = "table_tennis"
  s.version = TableTennis::VERSION
  s.authors = ["Adam Doppelt"]
  s.email = "amd@gurge.com"

  s.summary = "Stylish tables in your terminal."
  s.homepage = "https://github.com/gurgeous/table_tennis"
  s.license = "MIT"
  s.required_ruby_version = ">= 3.0.0"
  s.metadata = {
    "homepage_uri" => s.homepage,
    "rubygems_mfa_required" => "true",
    "source_code_uri" => s.homepage,
  }

  # what's in the gem?
  s.files = `git ls-files`.split("\n").grep_v(%r{^(bin|demo|test)/})
  s.require_paths = ["lib"]

  # gem dependencies
  s.add_dependency "csv", "~> 3.3" # required for Ruby 3.4+
  s.add_dependency "ffi", "~> 1.17" # required for Ruby 3.2+
  s.add_dependency "memo_wise", "~> 1.11"
  s.add_dependency "paint", "~> 2.3"
  s.add_dependency "unicode-display_width", "~> 3.1"
end
