export _NVIM_IN_JUST := "1"

# Build nvim and clear lua bytecode cache (prevents stale undofile/settings)
build:
    nix build --no-eval-cache
    trash ~/.cache/nvim/luac/
