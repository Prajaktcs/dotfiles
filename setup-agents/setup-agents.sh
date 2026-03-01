#!/bin/bash
# setup-agents.sh
# Sets up ~/.agents as the canonical store for all AI agent instructions
# and creates the appropriate symlinks and skill packages for each agent.

set -e

AGENTS_DIR="$HOME/.agents"
BASE_FILE="$AGENTS_DIR/base.md"
SKILLS_SRC="$AGENTS_DIR/antigravity/skills"

echo "🔧 Setting up ~/.agents directory structure..."

# -------------------------------------------------------------------
# 1. Create directory structure
# -------------------------------------------------------------------
mkdir -p \
  "$AGENTS_DIR/claude" \
  "$AGENTS_DIR/gemini" \
  "$AGENTS_DIR/antigravity/skills" \
  "$AGENTS_DIR/cursor" \
  "$AGENTS_DIR/copilot" \
  "$AGENTS_DIR/windsurf"

echo "✅ Directory structure created at $AGENTS_DIR"

# -------------------------------------------------------------------
# 2. Check for base.md
# -------------------------------------------------------------------
if [ ! -f "$BASE_FILE" ]; then
  echo ""
  echo "⚠️  No base.md found at $BASE_FILE"
  echo "   Please copy your base instructions there before continuing."
  echo "   Example: cp /path/to/CLAUDE.md $BASE_FILE"
  echo ""
fi

# -------------------------------------------------------------------
# 3. Claude Code
#    Global instructions: ~/.claude/CLAUDE.md
# -------------------------------------------------------------------
mkdir -p "$HOME/.claude"

CLAUDE_SRC="$AGENTS_DIR/claude/CLAUDE.md"
CLAUDE_DST="$HOME/.claude/CLAUDE.md"

if [ ! -f "$CLAUDE_SRC" ]; then
  cp "$BASE_FILE" "$CLAUDE_SRC" 2>/dev/null || touch "$CLAUDE_SRC"
  echo "📄 Created $CLAUDE_SRC (seeded from base.md)"
fi

ln -sf "$CLAUDE_SRC" "$CLAUDE_DST"
echo "🔗 Claude:      $CLAUDE_DST → $CLAUDE_SRC"

# -------------------------------------------------------------------
# 4. Gemini CLI
#    Global instructions: ~/.gemini/GEMINI.md
#    Uses @import syntax to reference base.md directly
# -------------------------------------------------------------------
mkdir -p "$HOME/.gemini"

GEMINI_SRC="$AGENTS_DIR/gemini/GEMINI.md"
GEMINI_DST="$HOME/.gemini/GEMINI.md"

if [ ! -f "$GEMINI_SRC" ]; then
  cat > "$GEMINI_SRC" <<EOF
# Gemini CLI — Global Instructions
#
# Base instructions are imported from the shared base.md.
# Add any Gemini-specific overrides below the import.

@$BASE_FILE

# -------------------------------------------------------------------
# Gemini-specific overrides (if any)
# -------------------------------------------------------------------
EOF
  echo "📄 Created $GEMINI_SRC (with @import of base.md)"
fi

ln -sf "$GEMINI_SRC" "$GEMINI_DST"
echo "🔗 Gemini:      $GEMINI_DST → $GEMINI_SRC"

# -------------------------------------------------------------------
# 5. Antigravity Skills
#    Global skills: ~/.gemini/antigravity/skills/
#    Each skill is a directory with a SKILL.md file.
#    Skills in ~/.agents/antigravity/skills/ are symlinked into place.
# -------------------------------------------------------------------
ANTIGRAVITY_SKILLS_DST="$HOME/.gemini/antigravity/skills"
mkdir -p "$ANTIGRAVITY_SKILLS_DST"

if [ -d "$SKILLS_SRC" ]; then
  for skill_dir in "$SKILLS_SRC"/*/; do
    if [ -d "$skill_dir" ]; then
      skill_name=$(basename "$skill_dir")
      skill_dst="$ANTIGRAVITY_SKILLS_DST/$skill_name"
      ln -sfn "$skill_dir" "$skill_dst"
      echo "🔗 Antigravity: $skill_dst → $skill_dir"
    fi
  done
else
  echo "⚠️  No skills found at $SKILLS_SRC — add skill directories there to activate them"
fi

# -------------------------------------------------------------------
# 6. Cursor
#    Global rules: ~/.cursor/rules/base.mdc
# -------------------------------------------------------------------
mkdir -p "$HOME/.cursor/rules"

CURSOR_SRC="$AGENTS_DIR/cursor/.cursorrules"
CURSOR_DST="$HOME/.cursor/rules/base.mdc"

if [ ! -f "$CURSOR_SRC" ]; then
  cat > "$CURSOR_SRC" <<EOF
# Cursor — Global Rules
# Add any Cursor-specific overrides here.
# Base instructions are maintained in ~/.agents/base.md

$(cat "$BASE_FILE" 2>/dev/null || echo "# (base.md not found — paste content here)")
EOF
  echo "📄 Created $CURSOR_SRC"
fi

ln -sf "$CURSOR_SRC" "$CURSOR_DST"
echo "🔗 Cursor:      $CURSOR_DST → $CURSOR_SRC"

# -------------------------------------------------------------------
# 7. GitHub Copilot
#    Project-level only — no global equivalent
# -------------------------------------------------------------------
COPILOT_SRC="$AGENTS_DIR/copilot/copilot-instructions.md"

if [ ! -f "$COPILOT_SRC" ]; then
  cp "$BASE_FILE" "$COPILOT_SRC" 2>/dev/null || touch "$COPILOT_SRC"
  echo "📄 Created $COPILOT_SRC (seeded from base.md)"
fi

echo "ℹ️  Copilot:     No global file supported. Use 'agents-copilot-init' in any repo."

# -------------------------------------------------------------------
# 8. Windsurf
#    Project-level only — no global equivalent
# -------------------------------------------------------------------
WINDSURF_SRC="$AGENTS_DIR/windsurf/.windsurfrules"

if [ ! -f "$WINDSURF_SRC" ]; then
  cp "$BASE_FILE" "$WINDSURF_SRC" 2>/dev/null || touch "$WINDSURF_SRC"
  echo "📄 Created $WINDSURF_SRC (seeded from base.md)"
fi

echo "ℹ️  Windsurf:    No global file supported. Use 'agents-windsurf-init' in any repo."

# -------------------------------------------------------------------
# 9. Shell helper functions
# -------------------------------------------------------------------
SHELL_RC="$HOME/.zshrc"
[ ! -f "$SHELL_RC" ] && SHELL_RC="$HOME/.bashrc"

MARKER="# >>> agents-helpers >>>"

if ! grep -q "$MARKER" "$SHELL_RC" 2>/dev/null; then
  cat >> "$SHELL_RC" <<'SHELL'

# >>> agents-helpers >>>
# Helper functions for ~/.agents setup

# Inject Copilot instructions into current repo
agents-copilot-init() {
  mkdir -p .github
  cp ~/.agents/copilot/copilot-instructions.md .github/copilot-instructions.md
  echo "✅ Copilot instructions copied to .github/copilot-instructions.md"
}

# Inject Windsurf rules into current repo
agents-windsurf-init() {
  cp ~/.agents/windsurf/.windsurfrules .windsurfrules
  echo "✅ Windsurf rules copied to .windsurfrules"
}

# Create a new Antigravity skill scaffold
agents-skill-new() {
  local name="$1"
  if [ -z "$name" ]; then
    echo "Usage: agents-skill-new <skill-name>"
    return 1
  fi
  local skill_dir="$HOME/.agents/antigravity/skills/$name"
  mkdir -p "$skill_dir"
  cat > "$skill_dir/SKILL.md" <<EOF
---
name: $name
description: Describe when this skill should be activated. Be specific about triggers and keywords.
---

# Skill Title

## When to use this skill
- Use case 1
- Use case 2

## Do not use this skill when
- Exclusion 1

## Instructions

Add your conventions, patterns, and rules here.
EOF
  ln -sfn "$skill_dir" "$HOME/.gemini/antigravity/skills/$name"
  echo "✅ Created skill scaffold at $skill_dir"
  echo "   Symlinked to ~/.gemini/antigravity/skills/$name"
  echo "   Edit $skill_dir/SKILL.md to add your instructions."
}

# Show status of all active agent instructions
agents-status() {
  echo ""
  echo "🤖 Agent Instruction Status"
  echo "─────────────────────────────────────────────────"
  _agents_check "$HOME/.claude/CLAUDE.md"          "Claude Code   (global)"
  _agents_check "$HOME/.gemini/GEMINI.md"          "Gemini CLI    (global)"
  _agents_check "$HOME/.cursor/rules/base.mdc"     "Cursor        (global)"
  echo ""
  echo "Antigravity Skills (global):"
  local skills_dir="$HOME/.gemini/antigravity/skills"
  if [ -d "$skills_dir" ] && [ "$(ls -A $skills_dir)" ]; then
    for skill in "$skills_dir"/*/; do
      printf "  ✅ %s\n" "$(basename $skill)"
    done
  else
    echo "  ❌ No skills found at $skills_dir"
  fi
  echo ""
  echo "Project-scoped (run from inside a repo):"
  _agents_check ".github/copilot-instructions.md"  "Copilot"
  _agents_check ".windsurfrules"                    "Windsurf"
  echo ""
}

_agents_check() {
  local path="$1" label="$2"
  if [ -L "$path" ]; then
    printf "  ✅ %-30s %s → %s\n" "$label" "$path" "$(readlink $path)"
  elif [ -f "$path" ]; then
    printf "  ✅ %-30s %s\n" "$label" "$path"
  else
    printf "  ❌ %-30s not found\n" "$label"
  fi
}
# <<< agents-helpers <<<
SHELL

  echo ""
  echo "✅ Shell helpers added to $SHELL_RC"
  echo "   Run 'source $SHELL_RC' or open a new terminal to activate."
fi

# -------------------------------------------------------------------
# Done
# -------------------------------------------------------------------
echo ""
echo "🎉 Setup complete!"
echo ""
echo "Directory structure:"
find "$AGENTS_DIR" -type f | sort | sed "s|$HOME|~|g" | awk '{print "   " $0}'
echo ""
echo "Next steps:"
echo "  1. Ensure your base instructions are at ~/.agents/base.md"
echo "  2. Run 'source $SHELL_RC' to activate shell helpers"
echo "  3. Run 'agents-status' to verify everything is wired up"
echo "  4. Add new Antigravity skills with 'agents-skill-new <name>'"
echo "  5. Use 'agents-copilot-init' or 'agents-windsurf-init' inside any repo"
