# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Zerocracy
# SPDX-License-Identifier: MIT

def say(txt)
  txt.gsub('{name}', %w[Jeff Nicole Peter Sarah John Natasha].sample)
end
