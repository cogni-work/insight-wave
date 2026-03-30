#!/usr/bin/env bash
# Workplace Orchestrator - Claude Code Launcher
# Version: 4.0.0
# Plugin: cogni-workspace
# Launches Claude Code with language-specific output-style from Obsidian Terminal

set -e

# Configuration - substituted by setup script
WORKPLACE_ROOT="{{WORKPLACE_ROOT_WSL}}"
CLAUDE_CMD=""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

show_header() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║    ${BLUE}${BOLD}WORKPLACE${NC}${CYAN} with claude code          ║${NC}"
    echo -e "${CYAN}║      ${MAGENTA}cogni-workspace v4.0.0${CYAN}             ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
    echo
}

setup_claude_path() {
    local claude_locations=(
        "$HOME/.local/bin/claude"
        "$HOME/.npm-global/bin/claude"
        "/usr/local/bin/claude"
        "/opt/homebrew/bin/claude"
    )

    # Try npm prefix if available
    local npm_prefix
    npm_prefix="$(npm config get prefix 2>/dev/null || true)"
    if [[ -n "$npm_prefix" ]]; then
        claude_locations+=("${npm_prefix}/bin/claude")
    fi

    for location in "${claude_locations[@]}"; do
        if [[ -x "$location" ]]; then
            CLAUDE_CMD="$location"
            return 0
        fi
    done

    if command -v claude &>/dev/null; then
        CLAUDE_CMD="claude"
        return 0
    fi

    return 1
}

select_language() {
    local default_lang="en"
    if [[ -f "$WORKPLACE_ROOT/.workplace-config.json" ]] && command -v jq &>/dev/null; then
        default_lang="$(jq -r '.language // "en"' "$WORKPLACE_ROOT/.workplace-config.json" 2>/dev/null || echo "en")"
    fi

    echo -e "${YELLOW}Language:${NC}" >&2
    echo -e "  ${GREEN}1${NC}) English" >&2
    echo -e "  ${GREEN}2${NC}) Deutsch" >&2
    echo -e "  ${GREEN}3${NC}) Default (${default_lang})" >&2
    echo "" >&2
    echo -ne "${GREEN}Choose (1-3, default: 3): ${NC}" >&2
    read -r lang_choice

    case "$lang_choice" in
        1) echo "en" ;;
        2) echo "de" ;;
        3|"") echo "$default_lang" ;;
        *) echo "$default_lang" ;;
    esac
}

select_permission_mode() {
    echo -e "${YELLOW}Permission Mode:${NC}" >&2
    echo -e "  ${GREEN}1${NC}) Standard — approval required for each operation" >&2
    echo -e "  ${GREEN}2${NC}) Auto-approved — uninterrupted workflow" >&2
    echo "" >&2
    echo -ne "${GREEN}Choose (1-2, default: 1): ${NC}" >&2
    read -r mode_choice

    case "$mode_choice" in
        2) echo "bypass" ;;
        *) echo "standard" ;;
    esac
}

copy_claude_template() {
    local lang="$1"
    local template="$WORKPLACE_ROOT/.claude/templates/CLAUDE.${lang}.md"
    local destination="$WORKPLACE_ROOT/CLAUDE.md"

    if [[ -f "$template" ]]; then
        cp "$template" "$destination"
        echo -e "${GREEN}✓${NC} CLAUDE.md updated for ${lang}" >&2
    else
        echo -e "${YELLOW}⚠${NC} Template CLAUDE.${lang}.md not found (keeping existing)" >&2
    fi
}

launch_claude() {
    cd "$WORKPLACE_ROOT"

    # Source workplace environment
    if [[ -f "$WORKPLACE_ROOT/.workplace-env.sh" ]]; then
        # shellcheck disable=SC1091
        source "$WORKPLACE_ROOT/.workplace-env.sh"
    fi

    echo -e "${GREEN}Launching Claude Code...${NC}"
    echo -e "Workplace: ${BLUE}${WORKPLACE_ROOT}${NC}"
    echo ""

    local LANGUAGE
    LANGUAGE="$(select_language)"
    echo ""

    copy_claude_template "$LANGUAGE"
    echo ""

    # Resolve output-style
    local OUTPUT_STYLE_FILE="$WORKPLACE_ROOT/.claude/output-styles/workplace-${LANGUAGE}.md"
    local FALLBACK_OUTPUT_STYLE="$WORKPLACE_ROOT/.claude/output-styles/workplace-en.md"

    if [[ ! -f "$OUTPUT_STYLE_FILE" ]]; then
        if [[ "$LANGUAGE" != "en" ]] && [[ -f "$FALLBACK_OUTPUT_STYLE" ]]; then
            echo -e "${YELLOW}⚠${NC} workplace-${LANGUAGE}.md not found, using English" >&2
            LANGUAGE="en"
            OUTPUT_STYLE_FILE="$FALLBACK_OUTPUT_STYLE"
        else
            echo -e "${YELLOW}⚠${NC} No output-style found, starting without it" >&2
            OUTPUT_STYLE_FILE=""
        fi
    fi

    if [[ -n "$OUTPUT_STYLE_FILE" ]]; then
        echo -e "${GREEN}Output-style:${NC} workplace-${LANGUAGE}"
        echo -e "${CYAN}Activate with:${NC} /output-style workplace-${LANGUAGE}"
    fi
    echo ""

    local PERMISSION_MODE
    PERMISSION_MODE="$(select_permission_mode)"
    echo ""
    echo "──────────────────────────"
    echo ""

    if [[ "$PERMISSION_MODE" == "bypass" ]]; then
        exec "$CLAUDE_CMD" --permission-mode bypassPermissions
    else
        exec "$CLAUDE_CMD"
    fi
}

main() {
    export PATH="$HOME/bin:$HOME/.local/bin:$HOME/.npm-global/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:$PATH"

    if ! setup_claude_path; then
        echo -e "${RED}Claude Code not found${NC}"
        echo "Install: npm install -g @anthropic-ai/claude-code"
        echo ""
        echo "Starting shell instead..."
        cd "$WORKPLACE_ROOT"
        [[ -f "$WORKPLACE_ROOT/.workplace-env.sh" ]] && source "$WORKPLACE_ROOT/.workplace-env.sh"
        exec "${SHELL:-bash}"
    fi

    show_header
    launch_claude
}

main "$@"
