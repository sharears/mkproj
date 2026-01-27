#!/usr/bin/env bash
#
# mkproj.sh
# One-command setup for a reproducible research project (local + GitHub)
#

mkproj () {

  PROJECT="$1"

  # -------------------------
  # Basic checks
  # -------------------------
  if [ -z "$PROJECT" ]; then
    echo "Usage: mkproj <project_name>"
    return 1
  fi

  if ! command -v git >/dev/null 2>&1; then
    echo "Error: git is required but not installed."
    return 1
  fi

  if ! command -v gh >/dev/null 2>&1; then
    echo "Error: GitHub CLI (gh) is required."
    echo "Install from: https://cli.github.com/"
    return 1
  fi

  if [ -d "$PROJECT" ]; then
    echo "Error: directory '$PROJECT' already exists."
    return 1
  fi

  echo "📁 Creating project: $PROJECT"

  # -------------------------
  # Create directory structure
  # -------------------------
  mkdir -p "$PROJECT"/{data/{raw,intermediate,processed},scripts,notebooks,metadata,results,logs}
  cd "$PROJECT" || return 1

  # -------------------------
  # Top-level README
  # -------------------------
  cat <<EOF > README.md
# $PROJECT

## Overview
Project description.

## Structure
- data/      Local data only (not tracked in git)
- scripts/   Analysis and processing code
- notebooks/ Exploratory Jupyter notebooks
- metadata/  Data dictionaries and mappings
- results/   Derived outputs (not tracked)
- logs/      Daily analysis notes
EOF

  # -------------------------
  # Folder READMEs (so folders appear on GitHub)
  # -------------------------
  for d in scripts notebooks metadata; do
    cat <<EOF > "$d/README.md"
This directory contains files related to $d.
EOF
  done

  # -------------------------
  # Daily log
  # -------------------------
  touch logs/run_log.md

  # -------------------------
  # .gitignore
  # -------------------------
  cat <<'EOF' > .gitignore
# Data and results
data/
results/

# Jupyter
.ipynb_checkpoints/

# Python
__pycache__/
*.pyc

# OS
.DS_Store
Thumbs.db
EOF

  # -------------------------
  # Initialize git
  # -------------------------
  echo "🔧 Initializing git repository"
  git init >/dev/null
  git branch -M main
  git add .
  git commit -m "Initial project structure" >/dev/null

  # -------------------------
  # Create or connect GitHub repo
  # -------------------------
  echo "🌐 Creating or connecting GitHub repository"
  gh repo create "$PROJECT" --private --license MIT --confirm >/dev/null 2>&1 || true

  REMOTE_URL=$(gh repo view "$PROJECT" --json url -q .url 2>/dev/null)

  if [ -z "$REMOTE_URL" ]; then
    echo "Error: could not determine GitHub repository URL."
    return 1
  fi

  git remote add origin "$REMOTE_URL" 2>/dev/null || true

  # -------------------------
  # Sync histories safely
  # -------------------------
  echo "🔄 Syncing local and remote repositories"
  git pull origin main --no-rebase --allow-unrelated-histories >/dev/null 2>&1 || true

  # -------------------------
  # Push
  # -------------------------
  echo "🚀 Pushing to GitHub"
  git push -u origin main >/dev/null

  echo "✅ Project '$PROJECT' is ready and synced"
}
