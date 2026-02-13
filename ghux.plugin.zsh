#!/usr/bin/env zsh

# Thin compatibility wrapper:
# keep the `ghux` shell function name for existing plugin users,
# but delegate all behavior to the Go CLI binary.
function ghux() {
  if [[ -z "$(whence -p ghux)" ]]; then
    print -u2 -- "ghux binary not found in PATH"
    return 1
  fi
  command ghux "$@"
}
