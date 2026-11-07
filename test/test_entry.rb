# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require 'fileutils'
require 'open3'
require 'pathname'
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

      assert_real_path_used(run_entry(judges_stub(dir), home, File.join(dir, 'args.txt'), script: symlink_entry(dir)))
    end
  end

  def assert_real_path_used(passed)
    assert_equal(File.expand_path('../lib', __dir__), passed[passed.index('--lib') + 1])
    assert_equal(File.expand_path('../judges', __dir__), passed[passed.index('--lib') + 2])
  end

  def test_resolves_relative_symlink_chain_without_gnu_readlink
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, 'home'))
      bin = judges_stub(dir)
      bsd_readlink_stub(bin)
      script = relative_chain_entry(dir)
      passed = run_entry(bin, File.join(dir, 'home'), File.join(dir, 'args.txt'), script: script, chdir: dir)

      assert_real_path_used(passed)
    end
  end

  def test_resolves_slashless_script_name_found_through_path
    Dir.mktmpdir do |dir|
      bin = judges_stub(dir)
      FileUtils.ln_s(File.expand_path('../entry.sh', __dir__), File.join(bin, 'entry.sh'))
      home = File.join(dir, 'home')
      cwd = File.join(dir, 'cwd')
      FileUtils.mkdir_p([home, cwd])
      passed = run_entry(bin, home, File.join(dir, 'args.txt'), script: %w[bash entry.sh], chdir: cwd)

      assert_real_path_used(passed)
    end
  end

  def test_keeps_own_directory_when_slashless_script_is_not_in_path
    Dir.mktmpdir do |dir|
      FileUtils.cp(File.expand_path('../entry.sh', __dir__), File.join(dir, 'entry.sh'))
      FileUtils.mkdir_p(%w[lib judges home].map { |name| File.join(dir, name) })
      passed = run_entry(
        judges_stub(dir), "#{dir}/home", "#{dir}/args.txt", script: %w[bash entry.sh], chdir: dir
      )

      assert_equal(File.join(File.realpath(dir), 'lib'), passed[passed.index('--lib') + 1])
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

  def run_entry(bin, home, args, script: './entry.sh', chdir: Dir.pwd)
    stdout, stderr, status = Open3.capture3(
      { 'PATH' => "#{bin}:#{ENV.fetch('PATH')}", 'JUDGES_ARGS_FILE' => args },
      *script, 'job-42', home, chdir: chdir
    )

    assert_predicate(status, :success?, "#{stdout}\n#{stderr}")
    File.readlines(args, chomp: true)
  end

  def symlink_entry(dir)
    link = File.join(dir, 'linkdir', 'entry.sh')
    FileUtils.mkdir_p(File.dirname(link))
    FileUtils.ln_s(File.expand_path('../entry.sh', __dir__), link)
    link
  end

  def bsd_readlink_stub(bin)
    stub = File.join(bin, 'readlink')
    File.write(stub, <<~SH)
      #!/bin/sh
      [ "$1" = '-f' ] && { echo 'readlink: illegal option -- f' >&2; exit 1; }
      exec /usr/bin/readlink "$@"
    SH
    FileUtils.chmod(0o755, stub)
  end

  def relative_chain_entry(dir)
    first = File.join(dir, 'first')
    second = File.join(dir, 'second')
    FileUtils.mkdir_p([first, second])
    FileUtils.ln_s('../second/entry.sh', File.join(first, 'entry.sh'))
    real = File.realpath(second)
    rel = Pathname.new(File.expand_path('../entry.sh', __dir__)).relative_path_from(Pathname.new(real))
    FileUtils.ln_s(rel, File.join(second, 'entry.sh'))
    File.join(first, 'entry.sh')
  end
end
