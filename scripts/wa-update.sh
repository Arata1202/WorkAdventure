#!/bin/bash

set -euo pipefail

version_file="wa.version"
if [[ ! -f "${version_file}" ]]; then
  echo "ERROR: Version file not found: ${version_file}" >&2
  exit 1
fi
tag="$(tr -d '[:space:]' < "${version_file}")"
if [[ -z "${tag}" ]]; then
  echo "ERROR: Version file is empty: ${version_file}" >&2
  exit 1
fi

files=("$@")
if [[ ${#files[@]} -eq 0 ]]; then
  files=(".env.example" ".env")
fi

needs_env=false
for file in "${files[@]}"; do
  if [[ "${file}" == ".env" ]]; then
    needs_env=true
  fi
done

example_changed=true
if [[ -f ".env.example" ]]; then
  if ! grep -q '^VERSION=' ".env.example"; then
    echo "ERROR: No VERSION= line found in .env.example" >&2
    exit 1
  fi
  current_example_version="$(grep -m1 '^VERSION=' .env.example | cut -d= -f2-)"
  if [[ "${current_example_version}" == "${tag}" ]]; then
    example_changed=false
  fi
elif [[ "${needs_env}" == "true" ]]; then
  echo "ERROR: .env.example is required to decide whether to update .env" >&2
  exit 1
fi

did_decrypt=false
did_encrypt=false
encrypt_once() {
  if [[ "${did_decrypt}" == "true" && "${did_encrypt}" == "false" ]]; then
    did_encrypt=true
    make encrypt
  fi
}

if [[ "${needs_env}" == "true" && "${example_changed}" == "true" ]]; then
  make decrypt
  did_decrypt=true
  trap 'encrypt_once' EXIT
fi

updated_files=()
for file in "${files[@]}"; do
  if [[ "${file}" == ".env" && "${example_changed}" == "false" ]]; then
    continue
  fi
  if [[ ! -f "${file}" ]]; then
    echo "ERROR: File not found: ${file}" >&2
    exit 1
  fi
  if ! grep -q '^VERSION=' "${file}"; then
    echo "ERROR: No VERSION= line found in ${file}" >&2
    exit 1
  fi
  current_version="$(grep -m1 '^VERSION=' "${file}" | cut -d= -f2-)"
  if [[ "${current_version}" == "${tag}" ]]; then
    continue
  fi
  perl -0pi -e "s/^VERSION=.*/VERSION=${tag}/m" "${file}"
  updated_files+=("${file}")
done

if [[ "${did_decrypt}" == "true" ]]; then
  encrypt_once
  trap - EXIT
fi

if [[ ${#updated_files[@]} -gt 0 ]]; then
  echo "SUCCESS: Updated VERSION to ${tag} in: ${updated_files[*]}"
else
  echo "SKIP: VERSION already ${tag}; no files updated"
fi
