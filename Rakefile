# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Zerocracy
# SPDX-License-Identifier: MIT

require 'rubygems'
require 'rake'
require 'rake/clean'

ENV['RACK_ENV'] = 'test'

task default: %i[clean test judges rubocop]

require 'rake/testtask'
desc 'Run all unit tests'
Rake::TestTask.new(:test) do |test|
  require 'minitest/reporters'
  Minitest::Reporters.use! [Minitest::Reporters::SpecReporter.new]
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.warning = true
  test.verbose = false
end

desc 'Test all judges'
task :judges do
  live = ARGV.include?('--live') ? '' : '--disable live'
  sh "judges #{ARGV.include?('--verbose') ? '--verbose' : ''} test --no-log #{live} --lib lib judges"
end

require 'rubocop/rake_task'
desc 'Run RuboCop on all directories'
RuboCop::RakeTask.new(:rubocop) do |task|
  task.fail_on_error = true
end
