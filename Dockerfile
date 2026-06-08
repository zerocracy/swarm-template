# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

FROM ruby:3.4-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libsqlite3-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/swarm

COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs=4 --retry=3

COPY . .

ENTRYPOINT ["/opt/swarm/entry.sh"]
