# Codex account switcher

Switch the native Windows Codex CLI and VS Code extension between saved
`~/.codex/auth.json` credentials without repeatedly logging in and out.

## Install

Open PowerShell in this directory and run:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\install.ps1
```

Restart PowerShell or import the module immediately:

```powershell
Import-Module .\CodexSwitcher.psm1
```

## First-time account setup

While logged into the first Codex account:

```powershell
codex-account save personal
```

Log into the second account once, then save it:

```powershell
codex-account save work
```

## Usage

```powershell
codex-account list
codex-account current
codex-account use personal
codex-account use work
codex-account rename personal private
codex-account delete private
```

`delete` asks for confirmation and refuses to delete the active account. Switch
to a different account first. Deleting a saved account does not revoke its
credentials remotely; use Codex logout/account security controls if revocation
is required.

After `use`, run **Developer: Reload Window** from the VS Code command palette.
Close active Codex CLI sessions and start a new one after switching.

Saved credentials are under `~/.codex/accounts`. They are secrets: do not commit,
sync, email, or otherwise share this directory.
