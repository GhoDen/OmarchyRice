#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PAM_RULE='auth       sufficient                 libbiopass_pam.so'
POLKIT_CHANGED=0

install_pam_include() {
  local file="$1" tmp

  if sudo test -f "$file" && sudo grep -Fqx "$PAM_RULE" "$file"; then
    return 0
  fi

  tmp="$(sudo mktemp)"
  sudo awk -v rule="$PAM_RULE" '
    !inserted && $1 == "auth" {
      for (i = 1; i <= NF; i++) {
        if ($i == "pam_unix.so") {
          print rule
          inserted = 1
          break
        }
      }
    }
    {
      print
    }
    END {
      if (!inserted) print rule
    }
  ' "$file" | sudo tee "$tmp" >/dev/null
  if sudo cmp -s "$tmp" "$file"; then
    sudo rm -f "$tmp"
    return 0
  fi
  sudo install -m 0644 "$tmp" "$file"
  sudo rm -f "$tmp"
}

install_polkit_override() {
  local source="$REPO_DIR/systemd/polkit-agent-helper@.service.d/biopass.conf"
  local destination=/etc/systemd/system/polkit-agent-helper@.service.d/biopass.conf

  if sudo cmp -s "$source" "$destination"; then
    return 0
  fi

  sudo install -Dm0644 "$source" "$destination"
  POLKIT_CHANGED=1
}

main() {
  install_pam_include /etc/pam.d/system-auth
  install_pam_include /etc/pam.d/omarchy-lock-password

  install_polkit_override
  if (( POLKIT_CHANGED )); then
    sudo systemctl daemon-reload
    sudo systemctl try-restart polkit.service || true
  fi
}

main "$@"
