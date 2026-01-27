#!/usr/bin/env bash
#
# install.sh
# Install mkproj into ~/.zshrc or ~/.bashrc
#

set -e

# Determine shell config file
if [[ "$SHELL" == *"zsh"* ]]; then
  TARGET="$HOME/.zshrc"
elif [[ "$SHELL" == *"bash"* ]]; then
  TARGET="$HOME/.bashrc"
else
  echo "Unsupported shell. Please use bash or zsh."
  exit 1
fi

echo "Installing mkproj into $TARGET"

# Prevent duplicate installation
if grep -q "mkproj ()" "$TARGET"; then
  echo "mkproj already installed. Skipping."
  exit 0
fi

# Append mkproj function
echo "" >> "$TARGET"
echo "# ---- mkproj: project creation helper ----" >> "$TARGET"
cat mkproj.sh >> "$TARGET"

echo "Installation complete."
echo "Restart your terminal or run:"
echo "  source $TARGET"
