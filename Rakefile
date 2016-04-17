require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec) do |test|
  test.pattern = 'spec/controllers/{user,post}s_controller.rb'
end

task default: :spec
