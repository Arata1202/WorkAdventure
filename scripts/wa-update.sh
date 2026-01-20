#!/bin/bash

set -euo pipefail

repo_url="https://github.com/workadventure/workadventure"
latest_url="$(curl -sL -o /dev/null -w '%{url_effective}' "${repo_url}/releases/latest")"
tag="${latest_url##*/}"

if [[ -z "${tag}" || "${tag}" == "latest" ]]; then
  echo "ERROR: Failed to detect latest release tag from ${repo_url}" >&2
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
    break
  fi
done

if [[ "${needs_env}" == "true" ]]; then
  make decrypt
  trap 'make encrypt' EXIT
fi

for file in "${files[@]}"; do
  if [[ ! -f "${file}" ]]; then
    echo "ERROR: File not found: ${file}" >&2
    exit 1
  fi
  if ! grep -q '^VERSION=' "${file}"; then
    echo "ERROR: No VERSION= line found in ${file}" >&2
    exit 1
  fi
  perl -0pi -e "s/^VERSION=.*/VERSION=${tag}/m" "${file}"
done

echo "SUCCESS: Updated VERSION to ${tag} in: ${files[*]}"
