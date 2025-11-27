#!/usr/bin/env bash
set -euo pipefail

echo "=== Bitwarden Secrets Manager CLI (bws) setup ==="

# Determine a sensible default shell profile file
SHELL_NAME="${SHELL##*/}"
PROFILE_FILE=""
case "${SHELL_NAME}" in
  zsh)
    PROFILE_FILE="$HOME/.zshrc"
    ;;
  bash)
    # Prefer .bashrc if it exists, otherwise .bash_profile
    if [ -f "$HOME/.bashrc" ]; then
      PROFILE_FILE="$HOME/.bashrc"
    else
      PROFILE_FILE="$HOME/.bash_profile"
    fi
    ;;
  *)
    PROFILE_FILE="$HOME/.profile"
    ;;
esac

echo "Detected shell: ${SHELL_NAME:-unknown}"
echo "Using profile file: $PROFILE_FILE"

# Ensure the directory for the profile exists
mkdir -p "$(dirname "$PROFILE_FILE")"

INSTALL_BWS=0

if command -v bws >/dev/null 2>&1; then
  EXISTING_PATH="$(command -v bws)"
  echo "bws is already installed at: $EXISTING_PATH"
  read -r -p "Do you want to reinstall bws using the official Bitwarden install script? [y/N]: " REPLY
  case "$REPLY" in
    [yY][eE][sS]|[yY])
      INSTALL_BWS=1
      ;;
    *)
      INSTALL_BWS=0
      ;;
  esac
else
  echo "bws is not currently installed."
  read -r -p "Install bws using the official Bitwarden install script now? [Y/n]: " REPLY
  case "$REPLY" in
    [nN][oO]|[nN])
      INSTALL_BWS=0
      ;;
    *)
      INSTALL_BWS=1
      ;;
  esac
fi

if [ "$INSTALL_BWS" -eq 1 ]; then
  echo
  echo "Installing bws via official Bitwarden install script (may prompt for sudo)..."
  if ! curl -fsSL https://bws.bitwarden.com/install | sh; then
    echo "❌ Failed to install bws via Bitwarden install script."
    exit 1
  fi
else
  echo "Skipping bws installation."
fi

if ! command -v bws >/dev/null 2>&1; then
  echo "❌ bws is not available on PATH after installation attempt."
  echo "   Please ensure /usr/local/bin (or your chosen install path) is on your PATH and try again."
  exit 1
fi

echo
echo "bws appears to be installed successfully: $(command -v bws)"
(bws --version || true) 2>/dev/null

echo
read -r -p "Do you want to configure BWS_ACCESS_TOKEN now? [y/N]: " CONFIGURE_TOKEN
case "$CONFIGURE_TOKEN" in
  [yY][eE][sS]|[yY])
    ;;
  *)
    echo "Skipping BWS_ACCESS_TOKEN configuration."
    echo "You can export it manually later, for example:"
    echo '  export BWS_ACCESS_TOKEN="<your_machine_account_access_token>"'
    exit 0
    ;;
esac

echo
echo "Enter your Bitwarden Secrets Manager **machine account access token**."
echo "Input will be hidden; it will not be echoed back."
read -s -p "Access token: " BWS_TOKEN_INPUT
echo

if [ -z "$BWS_TOKEN_INPUT" ]; then
  echo "No token entered; aborting configuration."
  exit 1
fi

echo
read -r -p "Attempt a quick CLI check with this token (bws secret list --help)? [y/N]: " VALIDATE
if [[ "$VALIDATE" =~ ^([yY][eE][sS]|[yY])$ ]]; then
  echo "Running a quick validation (this does not list secrets, only checks CLI access)..."
  if ! BWS_ACCESS_TOKEN="$BWS_TOKEN_INPUT" bws secret list --help >/dev/null 2>&1; then
    echo "⚠️  Validation command did not succeed. This may indicate an invalid token or connectivity issue."
    read -r -p "Continue anyway and save this token? [y/N]: " CONTINUE_ANYWAY
    if [[ ! "$CONTINUE_ANYWAY" =~ ^([yY][eE][sS]|[yY])$ ]]; then
      echo "Aborting configuration at your request."
      exit 1
    fi
  else
    echo "✅ Validation command executed successfully."
  fi
fi

echo
echo "You can export this token for the current shell using (example):"
echo '  export BWS_ACCESS_TOKEN="<your_machine_account_access_token>"'

echo
echo "The next step can **persist** your token as plaintext in: $PROFILE_FILE"
echo "Only do this on a secure, single-user development machine."
read -r -p "Append BWS_ACCESS_TOKEN to $PROFILE_FILE now? [y/N]: " WRITE_TOKEN
if [[ "$WRITE_TOKEN" =~ ^([yY][eE][sS]|[yY])$ ]]; then
  {
    echo
    echo "# Bitwarden Secrets Manager CLI configuration"
    echo "export BWS_ACCESS_TOKEN=\"$BWS_TOKEN_INPUT\""
  } >> "$PROFILE_FILE"
  echo "✅ BWS_ACCESS_TOKEN appended to $PROFILE_FILE"
else
  echo "Skipped writing BWS_ACCESS_TOKEN to $PROFILE_FILE."
fi

echo
read -r -p "If you use n8n, enter a default Bitwarden project ID to export as N8N_BITWARDEN_PROJECT_ID (or press Enter to skip): " N8N_PROJECT_ID
if [ -n "$N8N_PROJECT_ID" ]; then
  read -r -p "Persist N8N_BITWARDEN_PROJECT_ID=$N8N_PROJECT_ID in $PROFILE_FILE? [y/N]: " WRITE_N8N
  if [[ "$WRITE_N8N" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    {
      echo
      echo "# Default Bitwarden project for n8n"
      echo "export N8N_BITWARDEN_PROJECT_ID=\"$N8N_PROJECT_ID\""
    } >> "$PROFILE_FILE"
    echo "✅ N8N_BITWARDEN_PROJECT_ID appended to $PROFILE_FILE"
  else
    echo "Skipped writing N8N_BITWARDEN_PROJECT_ID to $PROFILE_FILE."
  fi
fi

echo
echo "All done. Restart your shell or run:"
echo "  source \"$PROFILE_FILE\""
echo "to load the updated environment variables."
