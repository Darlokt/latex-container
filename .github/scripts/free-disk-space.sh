#!/usr/bin/env bash
set -euo pipefail

minimum_free_gb="${MINIMUM_FREE_GB:-35}"

# These paths contain preinstalled SDKs that this Docker-only workflow never uses.
cleanup_paths=(
  /opt/ghc
  /usr/local/lib/android
  /usr/local/share/boost
  /usr/local/share/powershell
  /usr/share/dotnet
)

for cleanup_path in "${cleanup_paths[@]}"; do
  if [[ -e "${cleanup_path}" ]]; then
    sudo rm -rf -- "${cleanup_path}"
  fi
done

sudo docker image prune --all --force >/dev/null

available_kb="$(df --output=avail -k / | tail -n 1 | tr -d ' ')"
available_gb="$((available_kb / 1024 / 1024))"
df -h /

if ((available_gb < minimum_free_gb)); then
  printf 'Only %s GiB is free; this build requires at least %s GiB.\n' \
    "${available_gb}" "${minimum_free_gb}" >&2
  printf '%s\n' 'Use a larger or self-hosted native runner with at least 50 GiB free.' >&2
  exit 1
fi
