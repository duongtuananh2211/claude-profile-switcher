#!/usr/bin/env bash

# Remove DeepSeek/custom gateway settings
unset ANTHROPIC_BASE_URL
unset ANTHROPIC_AUTH_TOKEN
unset ANTHROPIC_API_KEY

unset ANTHROPIC_MODEL
unset ANTHROPIC_DEFAULT_OPUS_MODEL
unset ANTHROPIC_DEFAULT_SONNET_MODEL
unset ANTHROPIC_DEFAULT_HAIKU_MODEL

# Disable alternative cloud providers, if previously enabled
unset CLAUDE_CODE_USE_BEDROCK
unset CLAUDE_CODE_USE_VERTEX
unset CLAUDE_CODE_SKIP_BEDROCK_AUTH
unset CLAUDE_CODE_SKIP_VERTEX_AUTH

echo "Switched Claude CLI back to Anthropic."
echo "Run: claude"
