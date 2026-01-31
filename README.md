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

## Full workflow for local n8n + Bitwarden

The typical end-to-end flow to use this repo with your local n8n environment is:

1. Clone this repository somewhere convenient (for example `~/bitwarden-secret-manager`).
2. Run the installer script:

   ```bash
   cd ~/bitwarden-secret-manager
   ./install-bws.sh
   ```

3. When prompted:

   - Decide whether to install or reinstall `bws` using Bitwarden's official install script (`curl https://bws.bitwarden.com/install | sh`).
   - Optionally provide your **machine account access token** so it can be exported as `BWS_ACCESS_TOKEN`.
   - Optionally provide your Bitwarden **project UUID** so it can be exported as `N8N_BITWARDEN_PROJECT_ID`.

4. In your local n8n repository (for example `~/businesses/repositories/n8n`):

   - Ensure that `docker-compose.yml` declares secret env vars by **name only** (for example `N8N_ENCRYPTION_KEY`, `N8N_BASIC_AUTH_USER`, etc.).
   - Use `./scripts/start-n8n.sh` to start n8n:

     ```bash
     cd ~/businesses/repositories/n8n
     ./scripts/start-n8n.sh
     ```

   - The script will detect `bws` and `BWS_ACCESS_TOKEN` and run:

     ```bash
     bws run --project-id "$N8N_BITWARDEN_PROJECT_ID" -- 'docker compose up -d'
     ```

     so secrets from your Bitwarden project are injected into the n8n container as environment variables.

## Region configuration (US, EU, self-hosted)

`bws` must talk to the same Bitwarden environment where your Secrets Manager account and machine account live.

Examples:

- **US cloud (default)**

  ```bash
  bws config server-base https://vault.bitwarden.com
  ```

- **EU cloud**

  ```bash
  bws config server-base https://vault.bitwarden.eu
  ```

- **Self-hosted**

  ```bash
  bws config server-base https://your.bitwarden.domain
  ```

These commands write configuration to `~/.config/bws/config`. You only need to run them once per environment (unless you change servers).

## Troubleshooting

- **`invalid value 'n8n' for '--project-id <PROJECT_ID>'` when using `bws run`**

  - `bws run --project-id` expects a **UUID**, not a project name.
  - Ensure `N8N_BITWARDEN_PROJECT_ID` (or the value you pass to `--project-id`) is the project **ID**, for example `6ae7d7ef-d853-4fac-a886-b3a101877b7b`, not `n8n`.

- **`[400 Bad Request] {"error":"invalid_client"}`**

  - Indicates Bitwarden has rejected the client credentials used by `bws`.
  - Common causes:
    - `BWS_ACCESS_TOKEN` is not a **Secrets Manager machine account access token**.
    - The token was copied incorrectly or has been revoked/expired.
    - `bws` is pointed at the wrong Bitwarden server (US vs EU vs self-host).
  - Fix:
    - Verify the server base URL:

      ```bash
      bws config server-base https://vault.bitwarden.eu   # for EU
      ```

      or the appropriate URL for your environment.

    - Regenerate the machine account access token in the Bitwarden UI and update `BWS_ACCESS_TOKEN` in your shell/profile.
    - Test the token directly:

      ```bash
      bws project list
      bws secret list <your_project_uuid>
      ```

- **`bws` not found**

  - Ensure that:
    - The installer successfully installed `bws` (for example to `/usr/local/bin/bws`).
    - The install location is present in your `PATH`.
  - Re-run `./install-bws.sh` if needed.
# CI/CD Status
