#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

set -e
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

if [ ! -d "${home}" ]; then
  echo "Directory '${home}' does not exist"
  exit 1
fi

if ! command -v judges &>/dev/null; then
  echo "'judges' executable not found. Make sure the 'judges' gem is installed."
  exit 1
fi

self=$(dirname "$(readlink -f "$0")")

set +e
output=$(judges update --summary --max-cycles=3 --no-log \
  --option "id=${id}" --lib "${self}/lib" "${self}/judges" "${home}/base.fb" 2>&1)
# shellcheck disable=SC2181
exit_code=$?
set -e

echo "${output}"

if [ "${exit_code}" -eq 0 ] && echo "${output}" | grep -q "Too many cycles already"; then
  echo "[FATAL] judges finished 3 cycle(s) without convergence. \
The factbase kept changing until --max-cycles was exhausted. \
Check judge logic or consider increasing --max-cycles."
  exit 75
fi

exit "${exit_code}"
