# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require 'factbase'
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
      args = File.join(dir, 'args.txt')
      passed = run_entry(judges_stub(dir), home, args)

      assert_includes(passed, 'update')
      assert_includes(passed, '--option')
      assert_includes(passed, 'id=job-42')
      assert_equal("#{home}/base.fb", passed.last)
    end
  end

  def test_runs_judges_and_writes_a_summary
    Dir.mktmpdir do |dir|
      path = File.join(dir, 'base.fb')
      write_initial_factbase(path)
      stdout, stderr, status = Open3.capture3('./entry.sh', 'job-42', dir)

      assert_predicate(status, :success?, "#{stdout}\n#{stderr}")
      updated = Factbase.new
      updated.import(File.binread(path))

      assert_equal(1, updated.query('(exists hello)').count)
      assert_equal(1, updated.query('(eq what "judges-summary")').count)
    end
  end

  private

  def write_initial_factbase(path)
    fb = Factbase.new
    fb.insert.hi = 'How are you?'
    File.binwrite(path, fb.export)
  end

  def judges_stub(dir)
    bin = File.join(dir, 'bin')
    FileUtils.mkdir_p(bin)
    stub = File.join(bin, 'judges')
    File.write(stub, JUDGES_STUB)
    FileUtils.chmod(0o755, stub)
    bin
  end

  def run_entry(bin, home, args, script: './entry.sh')
    stdout, stderr, status = Open3.capture3(
      { 'PATH' => "#{bin}:#{ENV.fetch('PATH')}", 'JUDGES_ARGS_FILE' => args },
      script, 'job-42', home
    )

    assert_predicate(status, :success?, "#{stdout}\n#{stderr}")
    File.readlines(args, chomp: true)
  end

  def symlink_entry(dir)
    link_dir = File.join(dir, 'linkdir')
    FileUtils.mkdir_p(link_dir)
    link = File.join(link_dir, 'entry.sh')
    FileUtils.ln_s(File.expand_path('../entry.sh', __dir__), link)
    link
  end
end
