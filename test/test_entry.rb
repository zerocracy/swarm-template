# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require 'fileutils'
require 'open3'
require 'tmpdir'
require_relative 'test__helper'

# Test for "entry.sh".
class TestEntry < Minitest::Test
  ENTRY = File.expand_path('../entry.sh', __dir__)

  JUDGES_STUB = <<~'RUBY'
    #!/usr/bin/env ruby
    File.write(ENV.fetch('JUDGES_ARGS_FILE'), ARGV.join("\n"))
  RUBY

  def test_resolves_real_path_when_invoked_via_symlink
    Dir.mktmpdir do |dir|
      home = File.join(dir, 'home')
      FileUtils.mkdir_p(home)

      assert_real_path_used(
        run_entry(judges_stub(dir), home, File.join(dir, 'args.txt'), script: symlink_entry(dir))
      )
    end
  end

  def assert_real_path_used(passed)
    assert_equal(File.expand_path('../lib', __dir__), passed[passed.index('--lib') + 1])
    assert_equal(File.expand_path('../judges', __dir__), passed[passed.index('--lib') + 2])
  end

  def test_forwards_job_id_to_judges_options
    Dir.mktmpdir do |dir|
      home = File.join(dir, 'home')
      FileUtils.mkdir_p(home)
      passed = run_entry(judges_stub(dir), home, File.join(dir, 'args.txt'))

      assert_includes(passed, 'update')
      assert_includes(passed, '--option')
      assert_equal(%w[id=job-42 job_id=job-42], passed.grep(/\A(?:job_)?id=/))
      assert_equal("#{home}/base.fb", passed.last)
    end
  end

  def test_forwards_job_id_verbatim_when_it_contains_shell_metacharacters
    Dir.mktmpdir do |dir|
      home = File.join(dir, 'home')
      FileUtils.mkdir_p(home)
      job = 'job 42; touch pwned $(id)'
      passed = run_entry(judges_stub(dir), home, File.join(dir, 'args.txt'), id: job)

      assert_equal(["id=#{job}", "job_id=#{job}"], passed.grep(/\A(?:job_)?id=/))
      refute_path_exists(File.join(dir, 'pwned'))
    end
  end

  def test_quotes_the_base_factbase_path_when_the_home_contains_spaces
    Dir.mktmpdir do |dir|
      home = File.join(dir, 'home with spaces')
      FileUtils.mkdir_p(home)
      passed = run_entry(judges_stub(dir), home, File.join(dir, 'args.txt'))

      assert_equal("#{home}/base.fb", passed.last)
    end
  end

  def test_refuses_to_run_when_the_arguments_are_not_usable
    Dir.mktmpdir do |dir|
      args = File.join(dir, 'args.txt')

      [
        [['', dir], 'The first argument must be the ID of the job to process'],
        [['job-42'], "The second argument must be the directory where 'base.fb' is located"],
        [['job-42', File.join(dir, 'missing')], 'does not exist']
      ].each do |argv, message|
        assert_includes(run_entry_failure(judges_stub(dir), argv, args), message)
      end
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

  def run_entry(bin, home, args, id: 'job-42', script: ENTRY)
    stdout, stderr, status, passed = invoke(bin, args, [id, home].compact, script)

    assert_predicate(status, :success?, "#{stdout}\n#{stderr}")
    passed
  end

  def run_entry_failure(bin, argv, args)
    stdout, stderr, status, passed = invoke(bin, args, argv, ENTRY)

    refute_predicate(status, :success?, "#{stdout}\n#{stderr}")
    assert_empty(passed, 'judges must not be executed')
    "#{stdout}\n#{stderr}"
  end

  def invoke(bin, args, argv, script)
    stdout, stderr, status = Open3.capture3(
      { 'PATH' => "#{bin}:#{ENV.fetch('PATH')}", 'JUDGES_ARGS_FILE' => args },
      script, *argv, chdir: File.dirname(args)
    )
    [stdout, stderr, status, File.exist?(args) ? File.readlines(args, chomp: true) : []]
  end

  def symlink_entry(dir)
    link_dir = File.join(dir, 'linkdir')
    FileUtils.mkdir_p(link_dir)
    link = File.join(link_dir, 'entry.sh')
    FileUtils.ln_s(ENTRY, link)
    link
  end
end
