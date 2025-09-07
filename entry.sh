#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Zerocracy
# SPDX-License-Identifier: MIT

set -ex
set -o pipefail

id=$1
if [ -z "${id}" ]; then
  echo "The first argument must be the ID of the job to process"
  exit 1
fi

home=$2
if [ -z "${home}" ]; then
  echo "The second argument must be the directory where 'base.fb' is located"
  exit 1
fi

self=$(dirname "$0")

judges --verbose update --quiet --summary --max-cycles=3 --no-log --lib "${self}/lib" "${self}/judges" "${home}/base.fb"
