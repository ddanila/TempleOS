# Repository workflow

This is a personal project. Work directly in `main` (or `master` if the default
branch is renamed). Do not create feature branches or additional worktrees for
new work. Existing experimental worktrees are historical evidence, not the place
to continue development.

Commit and push completed, verified changes within the active task's scope to
Danila's fork. Verify the remote destination first; do not push or open pull
requests upstream unless explicitly requested. Keep unrelated or unfinished
changes out of those commits.

Preserve unique build/test evidence during disk cleanup. Redundant generated
artifacts may be removed after verifying the retained copy or a lossless recovery
path. Keep cleanup manifests under `build/`.
