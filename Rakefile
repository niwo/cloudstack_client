require 'bundler'
require 'rake/testtask'

Bundler::GemHelper.install_tasks

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.pattern = "test/*_test.rb"
  t.warning = false
end

begin
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new
rescue LoadError
  desc "rubocop is not available"
  task :rubocop do
    abort "RuboCop is not available. Run `bundle install` first."
  end
end

desc "Run the API benchmark"
task :benchmark do
  ruby "-Ilib test/benchmark.rb"
end

desc "Run tests and RuboCop"
task default: %i[test rubocop]
