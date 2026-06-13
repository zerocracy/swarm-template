# Contributing

Read [these guidelines](https://www.yegor256.com/2014/04/15/github-guidelines.html).

## Quick Start

```bash
bundle install
bundle exec rake
```

## Before submitting a PR

1. Run `bundle exec rubocop` — 0 offenses
2. Run `bundle exec rake` — all tasks pass (test + judges + rubocop)
3. Keep HoC ≤ 133 (`gem install hoc && hoc master..HEAD`)
4. PR body must include `Fixes #<issue-number>`
5. Write PR description and commits in English
6. Post `@yegor256 please review` after creating the PR
