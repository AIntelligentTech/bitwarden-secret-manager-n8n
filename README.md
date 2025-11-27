# Bitwarden Secrets Manager CLI Helper

This repository provides a small helper script to install and configure the Bitwarden Secrets Manager CLI (`bws`) on a local development machine.

It is designed for:

- **Installing** the official `bws` binary via Bitwarden's install script.
- **Optionally configuring** environment variables such as `BWS_ACCESS_TOKEN` and `N8N_BITWARDEN_PROJECT_ID` for tools like n8n.
- Guiding you through the process via interactive prompts in the terminal.

## Requirements

- macOS or Linux with:
  - `curl`
  - `sh`/`bash`
  - (Optional) `sudo` access, if the installer chooses a system-wide path like `/usr/local/bin`.
- A Bitwarden account with **Secrets Manager** enabled.
- A **machine account** and **access token** for your Secrets Manager project.

## Usage

From this directory:

```bash
./install-bws.sh
```

The script will:

1. Check whether `bws` is already installed.
2. Offer to install or reinstall `bws` using Bitwarden's official install script.
3. Optionally prompt you for your Bitwarden machine account access token and (if you choose) append it as `BWS_ACCESS_TOKEN` to your shell profile.
4. Optionally configure a default Bitwarden project ID for use with tools like n8n as `N8N_BITWARDEN_PROJECT_ID`.

After running the script, restart your shell (or `source` your profile) so changes take effect.

## Security considerations

- Storing `BWS_ACCESS_TOKEN` in a shell profile (`~/.zshrc`, `~/.bashrc`, etc.) means it will be present in **plaintext** on disk.
- This can be acceptable on a locked-down development machine, but is **not recommended** on shared or untrusted systems.
- The script:
  - Never echoes the token back to the terminal.
  - Only writes it to a profile file if you explicitly confirm.
- Alternatively, you can skip persistence and export `BWS_ACCESS_TOKEN` manually in each shell or use a secure store (for example macOS Keychain) and a custom loader script.

## Relationship to n8n

If you are using n8n, you can:

- Set `N8N_BITWARDEN_PROJECT_ID` to your Bitwarden Secrets Manager project ID (for example, your local `n8n` project).
- Use scripts like your local `start-n8n.sh` to wrap `docker compose` calls with `bws run --project-id "$N8N_BITWARDEN_PROJECT_ID"` so secrets are injected at runtime.

This helper just standardizes the local `bws` installation and environment setup.
