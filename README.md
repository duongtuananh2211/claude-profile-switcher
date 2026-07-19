# claude-profiles

Switch Claude Code between different providers (official Anthropic, DeepSeek,
Z.AI, or any Anthropic-compatible gateway) with one command, without editing
env vars by hand every time.

Config (base URL, model, effort) and secrets (API keys) are stored
separately, so reinstalling never wipes out a saved key.

## Install

```bash
git clone <this-repo> claude_profiles
cd claude_profiles
./install.sh
```

This copies the bundled profiles and the `claude-profile` shell function into
`~/.claude_profiles/`, and hooks it into `~/.bashrc` and `~/.zshrc` (adds a
single marked block, safe to re-run).

Restart your shell (or `source ~/.zshrc`) afterwards.

Re-running `./install.sh` any time (e.g. after `git pull`) re-syncs the
bundled profiles and the switcher function — it never touches your saved API
keys.

## Usage

```bash
claude-profile <name>          # switch to a profile, then run `claude`
claude-profile add [name]      # create/update a profile (interactive wizard)
claude-profile remove [name]   # delete a profile (config + saved key)
claude-profile list            # list available profiles
```

### Creating a profile

```bash
claude-profile add deepseek
```

The wizard asks you to pick a provider:

1. **anthropic** — official API, no base URL/key override needed
2. **deepseek** — DeepSeek's Anthropic-compatible gateway
3. **z.ai** — Z.AI's GLM models via their Anthropic-compatible gateway
4. **custom** — any other Anthropic-compatible gateway (you supply the base
   URL and model names)

Then it asks for the model(s), your API key (input hidden), and an effort
level (`low` / `medium` / `high` / `max`).

Re-running `add` on an existing profile lets you update its settings; leaving
the API key blank keeps the previously saved key instead of clearing it.

### Switching profiles

```bash
claude-profile deepseek
claude
```

```bash
claude-profile claude   # back to official Anthropic API
claude
```

## How it works / layout

```
~/.claude_profiles/
├── profiles/            # config: base URL, model, effort — no secrets.
│                         # Safe to overwrite; install.sh re-syncs this every run.
│   ├── claude.bashrc
│   └── <your-profiles>.bashrc
├── secrets/              # API keys only (chmod 700 dir, chmod 600 files).
│                         # install.sh never touches this directory.
│   └── <your-profiles>.env
└── switcher.bashrc        # defines the `claude-profile` shell function
```

Switching a profile sources `profiles/<name>.bashrc` then
`secrets/<name>.env` on top, so the key always applies on top of the current
config.

## Repo layout

```
claude_profiles/
├── install.sh              # installer, safe to re-run
├── switcher.bashrc          # source of truth for the `claude-profile` function
├── profiles/
│   └── claude.bashrc         # bundled profile: reset back to official Anthropic API
└── templates/
    └── provider.bashrc.tmpl  # reference example for hand-writing a profile config
```

## Uninstall

```bash
rm -rf ~/.claude_profiles
```

Then remove the marked block (between `# >>> claude-profiles switcher >>>`
and `# <<< claude-profiles switcher <<<`) from `~/.bashrc` and `~/.zshrc`.
