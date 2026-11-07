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

  # Models a chain A→B→C→D→E plus the confirming cycle, so it needs five cycles.
  CHAIN_STUB = <<~'RUBY'
    #!/usr/bin/env ruby
    File.write(ENV.fetch('JUDGES_ARGS_FILE'), ARGV.join("\n"))
    args = ARGV.dup
    cap = 8
    while (arg = args.shift)
      if arg.start_with?('--max-cycles=')
        cap = arg.split('=', 2).last.to_i
      elsif arg == '--max-cycles'
        cap = args.shift.to_i
      end
    end
    abort("chain needs 5 cycles, got #{cap}") if cap < 5
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

  def test_allows_chain_longer_than_three_cycles
    Dir.mktmpdir do |dir|
      home = File.join(dir, 'home')
      FileUtils.mkdir_p(home)
      run_entry(judges_stub(dir, CHAIN_STUB), home, File.join(dir, 'args.txt'))
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

  def judges_stub(dir, source = JUDGES_STUB)
    bin = File.join(dir, 'bin')
    FileUtils.mkdir_p(bin)
    stub = File.join(bin, 'judges')
    File.write(stub, source)
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
