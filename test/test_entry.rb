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

  def test_resolves_real_path_when_invoked_via_symlink
    Dir.mktmpdir do |dir|
      home = File.join(dir, 'home')
      FileUtils.mkdir_p(home)
      link_dir = File.join(dir, 'linkdir')
      FileUtils.mkdir_p(link_dir)
      link = File.join(link_dir, 'entry.sh')
      FileUtils.ln_s(File.expand_path('../entry.sh', __dir__), link)
      args = File.join(dir, 'args.txt')
      bin = judges_stub(dir)
      stdout, stderr, status = Open3.capture3(
        { 'PATH' => "#{bin}:#{ENV.fetch('PATH')}", 'JUDGES_ARGS_FILE' => args },
        link, 'job-42', home
      )

      assert_predicate(status, :success?, "#{stdout}\n#{stderr}")
      passed = File.readlines(args, chomp: true)
      lib = passed[passed.index('--lib') + 1]
      judges = passed[passed.index('--lib') + 2]

      assert_equal(File.expand_path('../lib', __dir__), lib)
      assert_equal(File.expand_path('../judges', __dir__), judges)
    end
  end

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
