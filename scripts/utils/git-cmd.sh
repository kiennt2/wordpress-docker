#!/bin/bash

GIT_CMD() {
  if [[ $EUID -eq 0 ]]; then
    # If running as root (via sudo), execute git command as the original user
    # SUDO_USER is automatically set by sudo to the invoking user
    local REAL_USER="${SUDO_USER:-$(ls -ld "$ROOT_DIR" | awk '{print $3}')}"
    su "$REAL_USER" -c "git -C \"$ROOT_DIR\" $*"
  else
    # Otherwise run normally
    git -C "$ROOT_DIR" "$@"
  fi
}
