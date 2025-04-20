require "bundler/setup"
require "rake/testtask"
require "bundler"
Bundler::GemHelper.install_tasks

Rake::TestTask.new do
  # let the user pass *.rb on the command line
  files = ARGV.grep(%r{^test/.*\.rb$}).sort
  _1.test_files = files.empty? ? FileList["test/**/test_*.rb"] : files
  # autoload test_helper
  _1.ruby_opts = ["-w", "-r#{File.realpath("test/test_helper.rb")}"]
end

task default: :test
