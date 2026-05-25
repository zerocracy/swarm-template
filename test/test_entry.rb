# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require 'fileutils'
require 'open3'
require 'tmpdir'
require_relative 'test__helper'

# Test for "entry.sh".
class TestEntry < Minitest::Test
  JUDGES_STUB = <<~'RUBY'
    #!/usr/bin/env ruby
    File.write(ENV.fetch('JUDGES_ARGS_FILE'), ARGV.join("\n"))
  RUBY

  def test_forwards_job_id_to_judges_options
    Dir.mktmpdir do |dir|
      home = File.join(dir, 'home')
      FileUtils.mkdir_p(home)
      args = File.join(dir, 'args.txt')
      passed = run_entry(judges_stub(dir), home, args)

      assert_includes(passed, 'update')
      assert_includes(passed, '--option')
      assert_includes(passed, 'id=job-42')
      assert_equal("#{home}/base.fb", passed.last)
    end
  end

  private

  def judges_stub(dir)
    bin = File.join(dir, 'bin')
    FileUtils.mkdir_p(bin)
    stub = File.join(bin, 'judges')
    File.write(stub, JUDGES_STUB)
    FileUtils.chmod(0o755, stub)
    bin
  end

  def run_entry(bin, home, args)
    stdout, stderr, status = Open3.capture3(
      { 'PATH' => "#{bin}:#{ENV.fetch('PATH')}", 'JUDGES_ARGS_FILE' => args },
      './entry.sh', 'job-42', home
    )

    assert_predicate(status, :success?, "#{stdout}\n#{stderr}")
    File.readlines(args, chomp: true)
  end
end
