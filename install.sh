#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILES_DIR="$HOME/.claude_profiles"
CONFIGS_DIR="$PROFILES_DIR/profiles"
SECRETS_DIR="$PROFILES_DIR/secrets"
SWITCHER_FILE="$PROFILES_DIR/switcher.bashrc"
MARKER="# >>> claude-profiles switcher >>>"
MARKER_END="# <<< claude-profiles switcher <<<"

# Config lives under profiles/ and is safe to overwrite on every install —
# it never contains secrets. Keys live under secrets/ and this script never
# touches that directory, so re-running install never wipes out saved keys.
mkdir -p "$CONFIGS_DIR" "$SECRETS_DIR"
chmod 700 "$SECRETS_DIR"

for f in "$SCRIPT_DIR"/profiles/*.bashrc; do
    name="$(basename "$f")"
    cp "$f" "$CONFIGS_DIR/$name"
    echo "Installed profile: $name"
done

cp "$SCRIPT_DIR/switcher.bashrc" "$SWITCHER_FILE"
echo "Installed switcher: $SWITCHER_FILE"

if [[ -d "$SCRIPT_DIR/templates" ]]; then
    mkdir -p "$PROFILES_DIR/templates"
    cp "$SCRIPT_DIR"/templates/*.tmpl "$PROFILES_DIR/templates/" 2>/dev/null || true
    echo "Installed templates: $PROFILES_DIR/templates"
fi

add_source_line() {
    local rc="$1"
    [[ -f "$rc" ]] || return 0
    if grep -qF "$MARKER" "$rc" 2>/dev/null; then
        return 0
    fi
    {
        echo ""
        echo "$MARKER"
        echo "[[ -f \"$SWITCHER_FILE\" ]] && source \"$SWITCHER_FILE\""
        echo "$MARKER_END"
    } >> "$rc"
    echo "Hooked switcher into: $rc"
}

add_source_line "$HOME/.bashrc"
add_source_line "$HOME/.zshrc"

echo ""
echo "Done. Restart your shell (or 'source ~/.zshrc') then run:"
echo "  claude-profile claude"
echo "  claude-profile add        # create a new profile interactively (anthropic / deepseek / z.ai / custom)"
echo "  claude-profile remove     # delete a profile (config + saved key)"
echo "  claude-profile list       # list all profiles"
