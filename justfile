export _NVIM_IN_JUST := "1"

# Build nvim and clear lua bytecode cache (prevents stale undofile/settings)
build:
    nix build --no-eval-cache
    trash ~/.cache/nvim/luac/

# Lua parse + headless startup smoke test (scripts/check.sh)
check:
    bash scripts/check.sh

# ── Git pipeline ─────────────────────────────────────────────────────────────
# Trimmed from ~/nixconfig/justfile (git-stage + git-commit-and-push-no-lint),
# minus the lint gate and secret scan that repo needs. Doppler is scoped here to
# project cb-daily / config dev via ~/.doppler/.doppler.yaml.

# Stage everything that isn't gitignored (result -> is ignored, so it stays out)
git-stage:
    #!/usr/bin/env bash
    set -euo pipefail
    if ! git diff --quiet || ! git diff --staged --quiet || [ -n "$(git ls-files --others --exclude-standard)" ]; then
        git add .
        echo "[STAGE] Changes staged."
    else
        echo "[OK] No changes to stage."
    fi

# Build an "Added: …; Modified: …" message from the staged file list, commit, sync
git-commit-and-push:
    #!/usr/bin/env bash
    set -euo pipefail

    echo "[CHECK] Checking repo status..."

    if git diff --staged --quiet; then
        echo "[OK] No changes to commit."
    else
        echo "[COMMIT] Generating smart commit message..."
        COMMIT_MSG=$(git diff --staged --name-status | awk '
          BEGIN {
            labels["A"] = "Added";
            labels["M"] = "Modified";
            labels["D"] = "Deleted";
            labels["R"] = "Renamed";
            labels["C"] = "Copied";
            label_order[1] = "A"; label_order[2] = "M";
            label_order[3] = "D"; label_order[4] = "R";
            label_order[5] = "C";
          }
          {
            code = substr($1, 1, 1);
            file = (code == "R" || code == "C") ? $3 : $2;
            bucket[code] = bucket[code] ? bucket[code] ", " file : file;
          }
          END {
            msg = "";
            for (i = 1; i <= length(label_order); i++) {
              key = label_order[i];
              if (bucket[key]) {
                if (msg != "") msg = msg "; ";
                msg = msg labels[key] ": " bucket[key];
              }
            }
            print msg;
          }
        ')
        [ -z "$COMMIT_MSG" ] && COMMIT_MSG="Updated nvim config"

        echo -e "[MSG] Commit message:\n$COMMIT_MSG"
        git commit -m "$COMMIT_MSG"
    fi

    echo "[RUN] Syncing with remote..."
    # Deliberate merge (not rebase): a conflict must stop here and be visible.
    if ! doppler run -- git pull; then
        echo "[STOP] git pull failed — merge conflict or network. Push NOT attempted."
        echo "       Resolve the conflict, then: just git-commit-and-push"
        exit 1
    fi
    doppler run -- git push

# Full pipeline: smoke test -> stage -> commit -> pull -> push
run: check
    just git-stage
    just git-commit-and-push
