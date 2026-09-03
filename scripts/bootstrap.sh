#!/bin/sh
set -eu

hermes_home="${HERMES_HOME:-/opt/data}"
bootstrap_source="${HERMES_BOOTSTRAP_SOURCE:-/opt/hermes-bootstrap}"

# Refuse partial public configuration updates. Existing private state remains intact.
test -r "$bootstrap_source/config.yaml"
test -r "$bootstrap_source/SOUL.md"

install_versioned_file() {
  source_file="$1"
  destination_file="$2"
  mode="$3"
  temporary_file="$(mktemp "$hermes_home/.bootstrap-XXXXXX")"

  trap 'rm -f "$temporary_file"' EXIT INT TERM
  install -m "$mode" "$source_file" "$temporary_file"
  mv -f "$temporary_file" "$destination_file"
  trap - EXIT INT TERM
}

mkdir -p "$hermes_home/workspace"
install_versioned_file "$bootstrap_source/config.yaml" "$hermes_home/config.yaml" 600
install_versioned_file "$bootstrap_source/SOUL.md" "$hermes_home/SOUL.md" 644

exec hermes gateway run
