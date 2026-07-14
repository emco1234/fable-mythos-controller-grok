#!/usr/bin/env bash
# Install fable-mythos-controller as a Grok plugin.
#
# Discovers the controller repo (this directory), copies the plugin layout
# into ~/.grok/plugins/fable-mythos-controller, and verifies with `grok inspect`.
#
# Usage:
#   bash install.sh           # installs to ~/.grok/plugins/fable-mythos-controller
#   bash install.sh --uninstall
#   bash install.sh --dry-run # print actions without doing them
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_NAME="fable-mythos-controller"
PLUGIN_DIR="$HOME/.grok/plugins/$PLUGIN_NAME"
SKILL_DIR="$HOME/.grok/skills/$PLUGIN_NAME"
SCRIPT_DEST="$SKILL_DIR/scripts"

DRY_RUN=0
UNINSTALL=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --uninstall) UNINSTALL=1 ;;
    -h|--help)
      sed -n '2,12p' "$0"
      exit 0
      ;;
    *) echo "Unknown arg: $arg" >&2; exit 2 ;;
  esac
done

run() {
  echo "+ $*"
  [[ $DRY_RUN -eq 0 ]] && "$@"
}

# ---- Uninstall path ----
if [[ $UNINSTALL -eq 1 ]]; then
  echo "Uninstalling $PLUGIN_NAME..."
  run rm -rf "$PLUGIN_DIR"
  run rm -rf "$SKILL_DIR"
  echo "Done. Run /plugins reload in Grok."
  exit 0
fi

# ---- Pre-flight ----
if [[ ! -f "$SCRIPT_DIR/controller_v2.py" ]]; then
  echo "ERROR: install.sh must run from the controller repo root" >&2
  echo "       (controller_v2.py not found at $SCRIPT_DIR)" >&2
  exit 1
fi

# ---- Install as Grok plugin (manifest + skills) ----
echo "Installing $PLUGIN_NAME plugin to $PLUGIN_DIR..."
run mkdir -p "$PLUGIN_DIR/skills/$PLUGIN_NAME/scripts"
run cp "$SCRIPT_DIR/plugin.json" "$PLUGIN_DIR/plugin.json"
run cp "$SCRIPT_DIR/skills/$PLUGIN_NAME/SKILL.md" \
        "$PLUGIN_DIR/skills/$PLUGIN_NAME/SKILL.md"
run cp "$SCRIPT_DIR/scripts/run-controller.sh" \
        "$PLUGIN_DIR/skills/$PLUGIN_NAME/scripts/run-controller.sh"
run chmod +x "$PLUGIN_DIR/skills/$PLUGIN_NAME/scripts/run-controller.sh"

# ---- Also install the skill standalone (so /fable-mythos-controller works
#      as a slash command even without plugin trust) ----
echo "Installing skill standalone to $SKILL_DIR..."
run mkdir -p "$SCRIPT_DEST"
run cp "$SCRIPT_DIR/skills/$PLUGIN_NAME/SKILL.md" "$SKILL_DIR/SKILL.md"
run cp "$SCRIPT_DIR/scripts/run-controller.sh" "$SCRIPT_DEST/run-controller.sh"
run chmod +x "$SCRIPT_DEST/run-controller.sh"

# ---- Write a small marker so the skill can find the controller dir ----
# The marker must point to the *controller repo root* (where controller_v2.py
# lives), NOT the plugin wrapper. The run-controller.sh helper uses this
# marker together with the sibling-of-scripts fallback. Writing the wrapper
# path here caused the controller to never be resolved at runtime.
cat > "$SKILL_DIR/.controller-dir" <<EOF
$SCRIPT_DIR
EOF

echo ""
echo "✅ Installed. Next steps:"
echo ""
echo "1. Reload Grok plugins:"
echo "     /plugins reload"
echo ""
echo "2. Verify the plugin is loaded:"
echo "     grok inspect"
echo "   You should see 'fable-mythos-controller' under Skills / Plugins."
echo ""
echo "3. Use it in chat:"
echo "     /fable-mythos-controller audit my code at <path>"
echo "   or just type:"
echo "     \"use the controller to verify foo.py\""
echo ""
echo "Uninstall with:"
echo "     bash $SCRIPT_DIR/install.sh --uninstall"