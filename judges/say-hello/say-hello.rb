# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Zerocracy
# SPDX-License-Identifier: MIT

require 'fbe/fb'

Fbe.fb.query('(and (exists hi) (absent hello))').each do |f|
  f.hello = say('Hello, {name}!')
end
