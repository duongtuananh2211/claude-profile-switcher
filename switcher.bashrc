_claude_profile_dir="$HOME/.claude_profiles"
_claude_profile_configs="$_claude_profile_dir/profiles"
_claude_profile_secrets="$_claude_profile_dir/secrets"

# Portable prompt-and-read: bash's `read -p` means "read from coprocess" in
# zsh, so we print the prompt ourselves and read plain. Usage:
#   _cp_ask varname "Prompt: "        -> visible input
#   _cp_ask varname "Prompt: " silent -> hidden input (like a password)
_cp_ask() {
    local __var="$1" __prompt="$2" __silent="${3:-}"
    printf '%s' "$__prompt"
    if [[ "$__silent" == "silent" ]]; then
        read -rs "$__var"
        echo
    else
        read -r "$__var"
    fi
}

claude-profile() {
    local cmd="$1"
    case "$cmd" in
        add)
            shift
            _claude_profile_add "$@"
            ;;
        remove|rm)
            shift
            _claude_profile_remove "$@"
            ;;
        list|"")
            _claude_profile_list
            ;;
        *)
            _claude_profile_use "$cmd"
            ;;
    esac
}

_claude_profile_list() {
    echo "Usage:"
    echo "  claude-profile <name>         switch to a profile"
    echo "  claude-profile add [name]     create/update a profile (interactive)"
    echo "  claude-profile remove [name]  delete a profile (config + saved key)"
    echo "  claude-profile list           list available profiles"
    echo ""
    echo "Available profiles:"
    find "$_claude_profile_configs" -maxdepth 1 -name '*.bashrc' \
        -printf '  %f\n' 2>/dev/null | sed 's/\.bashrc$//'
}

_claude_profile_use() {
    local name="$1"
    local config="$_claude_profile_configs/$name.bashrc"
    local secret="$_claude_profile_secrets/$name.env"

    if [[ ! -f "$config" ]]; then
        echo "Profile not found: $config"
        echo "Run: claude-profile add $name"
        return 1
    fi

    source "$config"

    if [[ -f "$secret" ]]; then
        source "$secret"
    else
        unset ANTHROPIC_AUTH_TOKEN
        echo "(no API key saved for '$name' — run: claude-profile add $name)"
    fi

    echo "Switched to Claude profile: $name"
}

_claude_profile_remove() {
    local name="$1"
    [[ -z "$name" ]] && _cp_ask name "Profile name to remove: "
    if [[ -z "$name" ]]; then
        echo "Profile name required."
        return 1
    fi

    local config="$_claude_profile_configs/$name.bashrc"
    local secret="$_claude_profile_secrets/$name.env"

    if [[ ! -f "$config" && ! -f "$secret" ]]; then
        echo "Profile not found: $name"
        return 1
    fi

    local ans
    _cp_ask ans "Delete profile '$name' (config + saved key)? [y/N] "
    [[ "$ans" =~ ^[Yy]$ ]] || { echo "Aborted."; return 1; }

    rm -f "$config" "$secret"
    echo "Removed profile: $name"
}

_claude_profile_add() {
    local name="$1"
    [[ -z "$name" ]] && _cp_ask name "Profile name: "
    if [[ -z "$name" ]]; then
        echo "Profile name required."
        return 1
    fi

    mkdir -p "$_claude_profile_configs" "$_claude_profile_secrets"
    local config="$_claude_profile_configs/$name.bashrc"
    local secret="$_claude_profile_secrets/$name.env"
    local existing_key=""
    [[ -f "$secret" ]] && existing_key="$(grep -o 'ANTHROPIC_AUTH_TOKEN=.*' "$secret" | cut -d= -f2-)"

    if [[ -f "$config" ]]; then
        local ans
        _cp_ask ans "Profile '$name' already exists. Overwrite config? [y/N] "
        [[ "$ans" =~ ^[Yy]$ ]] || { echo "Aborted."; return 1; }
    fi

    echo "Select provider:"
    echo "  1) anthropic  (official API)"
    echo "  2) deepseek   (DeepSeek, Anthropic-compatible gateway)"
    echo "  3) z.ai       (Z.AI GLM models, Anthropic-compatible gateway)"
    echo "  4) custom     (any other Anthropic-compatible gateway)"
    local choice provider base_url model haiku_model
    _cp_ask choice "Choice [1-4]: "

    case "$choice" in
        1)
            provider="anthropic"
            base_url=""
            _cp_ask model "Model (blank = CLI default): "
            _cp_ask haiku_model "Haiku/subagent model (blank = CLI default): "
            ;;
        2)
            provider="deepseek"
            base_url="https://api.deepseek.com/anthropic"
            _cp_ask model "Pro model [deepseek-v4-pro]: "
            model="${model:-deepseek-v4-pro}"
            _cp_ask haiku_model "Flash model [deepseek-v4-flash]: "
            haiku_model="${haiku_model:-deepseek-v4-flash}"
            ;;
        3)
            provider="zai"
            base_url="https://api.z.ai/api/anthropic"
            _cp_ask model "Opus/Sonnet model [GLM-4.7]: "
            model="${model:-GLM-4.7}"
            _cp_ask haiku_model "Haiku/subagent model [GLM-4.5-Air]: "
            haiku_model="${haiku_model:-GLM-4.5-Air}"
            ;;
        4)
            provider="custom"
            _cp_ask base_url "Base URL: "
            _cp_ask model "Model: "
            _cp_ask haiku_model "Haiku/subagent model: "
            ;;
        *)
            echo "Invalid choice."
            return 1
            ;;
    esac

    local auth_token prompt_suffix=""
    [[ -n "$existing_key" ]] && prompt_suffix=" (blank = keep existing)"
    _cp_ask auth_token "API key${prompt_suffix}: " silent
    [[ -z "$auth_token" && -n "$existing_key" ]] && auth_token="$existing_key"

    local effort
    _cp_ask effort "Effort level [low/medium/high/max, default medium]: "
    effort="${effort:-medium}"

    # --- config (safe to overwrite, no secrets, tracked/synced) ---
    {
        echo "# Claude Code profile: $name"
        echo "# Provider: $provider"
        echo "# Generated by 'claude-profile add' on $(date '+%Y-%m-%d')"
        echo ""
        if [[ -n "$base_url" ]]; then
            echo "export ANTHROPIC_BASE_URL=$base_url"
        else
            echo "# ANTHROPIC_BASE_URL not set (using official Anthropic API)"
        fi
        if [[ -n "$model" ]]; then
            echo "export ANTHROPIC_MODEL=$model"
            echo "export ANTHROPIC_DEFAULT_OPUS_MODEL=$model"
            echo "export ANTHROPIC_DEFAULT_SONNET_MODEL=$model"
        fi
        if [[ -n "$haiku_model" ]]; then
            echo "export ANTHROPIC_DEFAULT_HAIKU_MODEL=$haiku_model"
            echo "export CLAUDE_CODE_SUBAGENT_MODEL=$haiku_model"
        fi
        echo "export CLAUDE_EFFORT=$effort"
    } > "$config"

    # --- secret (never touched by install.sh) ---
    if [[ -n "$auth_token" ]]; then
        echo "export ANTHROPIC_AUTH_TOKEN=$auth_token" > "$secret"
        chmod 600 "$secret"
    fi

    echo ""
    echo "Created profile: $config"
    [[ -f "$secret" ]] && echo "Saved key: $secret" || echo "(no API key saved — run 'claude-profile add $name' again to set one)"
    echo "Switch to it with: claude-profile $name"
}
