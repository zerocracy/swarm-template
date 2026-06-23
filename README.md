# Swarm of Judges

[![rake](https://github.com/zerocracy/swarm-template/actions/workflows/rake.yml/badge.svg)](https://github.com/zerocracy/swarm-template/actions/workflows/rake.yml)

Use this repository as a template to create your own swarm of
[judges](https://github.com/yegor256/judges)
for [Zerocracy](https://www.zerocracy.com).

## What is a Judge?

A judge is a Ruby script that processes facts stored in a
[Factbase](https://github.com/yegor256/factbase) (`.fb` file).
Each judge reads existing facts via S-expression queries and creates new facts
based on business rules. Judges run in cycles until no new facts are produced.

## Project Structure

```text
judges/<name>/<name>.rb     — judge implementation, auto-discovered
judges/<name>/<name>.yml    — YAML test for the judge (data-driven)
lib/                        — shared Ruby libraries
test/test_*.rb              — Minitest unit tests
entry.sh                    — Docker entry point
```

## Quick Start

You will need [Ruby](https://www.ruby-lang.org/en/) 3.4+ and
[Bundler](https://bundler.io/) installed.

```bash
bundle install
bundle exec rake
```

## Adding a New Judge

1. Create a directory for your judge:

```bash
mkdir judges/hello-world
```

1. Write the judge logic in `judges/hello-world/hello-world.rb`:

```ruby
# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require 'fbe/fb'

Fbe.fb.query('(and (exists hi) (absent hello))').each do |f|
  f.hello = say('Hello, {name}!')
end
```

1. Write a YAML test in `judges/hello-world/hello-world.yml`:

```yaml
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT
---
runs: 2
input:
  -
    _id: 1
    what: something-else
    when: 2024-05-12T23:54:24Z
    hi: 'How are you?'
expected:
  - /fb[count(f)=1]
  - /fb/f[_id=1]/hello
```

1. Run the judge YAML tests:

```bash
bundle exec judges test --no-log --disable live --lib lib judges
```

1. Run the full build:

```bash
bundle exec rake
```

If everything is clean, your judge is ready.

## Commands

| Command | Purpose |
| --- | --- |
| `bundle exec rake` | Full build (test + judges + rubocop) |
| `bundle exec rake test` | Ruby unit tests only |
| `bundle exec judges test --no-log --disable live --lib lib judges` | Judge YAML tests |
| `bundle exec rubocop` | Code style check |
| `docker build -t swarm .` | Build Docker image (requires Dockerfile) |

## How to Contribute

Read
[these guidelines](https://www.yegor256.com/2014/04/15/github-guidelines.html).
Make sure your build is green before you submit your pull request.

## References

- [judges gem](https://github.com/yegor256/judges)
- [fbe gem](https://github.com/zerocracy/fbe)
- [Factbase](https://github.com/yegor256/factbase)
- [Zerocracy](https://www.zerocracy.com)
