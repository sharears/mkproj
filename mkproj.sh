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
# Create or connect GitHub repo (HPC-proof)
# -------------------------
echo "🌐 Creating or connecting GitHub repository"

if ! git remote get-url origin >/dev/null 2>&1; then
  echo "🔗 No GitHub remote found — creating repository"

  # Create repo on GitHub ONLY (no source, no push)
  if ! gh repo create "$PROJECT" --private --confirm; then
    echo "Error: failed to create GitHub repository."
    return 1
  fi

  # Determine GitHub username explicitly
  GH_USER=$(gh api user -q .login)

  if [ -z "$GH_USER" ]; then
    echo "Error: could not determine GitHub username."
    return 1
  fi

  # Manually add remote (rock-solid)
  git remote add origin "https://github.com/$GH_USER/$PROJECT.git"
fi

REMOTE_URL=$(git remote get-url origin 2>/dev/null)

echo "DEBUG: reached REMOTE_URL check"
git remote -v || echo "DEBUG: no remotes found"

if [ -z "$REMOTE_URL" ]; then
  echo "Error: could not determine GitHub repository URL."
  return 1
fi


  # -------------------------
  # Sync histories safely
  # -------------------------
  echo "🔄 Syncing local and remote repositories"

  # -------------------------
  # Push
  # -------------------------
  echo "🚀 Pushing to GitHub"
  git push -u origin main >/dev/null

  echo "✅ Project '$PROJECT' is ready and synced"
}
