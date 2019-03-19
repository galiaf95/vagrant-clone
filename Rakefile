require 'rubygems'
require 'bundler/setup'
require 'rspec/core/rake_task'

$stdout.sync = true
$stderr.sync = true

RSpec::Core::RakeTask.new(:integration) do |t|
  t.pattern = 'spec/integration/**/*_spec.rb'
end

RSpec::Core::RakeTask.new(:unit) do |t|
  t.pattern = 'spec/unit/**/*_spec.rb'
end

Bundler::GemHelper.install_tasks