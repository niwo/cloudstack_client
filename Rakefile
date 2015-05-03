require 'bundler'
require 'rake/testtask'

Bundler::GemHelper.install_tasks

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.pattern = "test/*_test.rb"
end
