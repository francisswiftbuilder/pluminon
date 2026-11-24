#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNTIME="$(cd "${1:?usage: test_bundled_git.sh <runtime-directory>}" && pwd)"
WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/pluminon-git-smoke.XXXXXX")"
trap 'printf "Smoke test workspace: %s\n" "$WORK_DIR"' EXIT
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null GIT_CONFIG_NOSYSTEM=1
export GIT_TERMINAL_PROMPT=0 GIT_ALLOW_PROTOCOL=file:https
export GIT_AUTHOR_NAME=Pluminon GIT_AUTHOR_EMAIL=smoke@example.com
export GIT_COMMITTER_NAME=Pluminon GIT_COMMITTER_EMAIL=smoke@example.com
export GIT_EXEC_PATH="$RUNTIME/libexec/git-core"
export GIT_TEMPLATE_DIR="$RUNTIME/share/git-core/templates"
export PATH="$RUNTIME/bin:/usr/bin:/bin:/usr/sbin:/sbin"
git --version
git init --bare --initial-branch=main "$WORK_DIR/remote.git"
git clone "$WORK_DIR/remote.git" "$WORK_DIR/first"
git -C "$WORK_DIR/first" commit --allow-empty -m 'test: initial commit'
git -C "$WORK_DIR/first" push -u origin main
git clone "$WORK_DIR/remote.git" "$WORK_DIR/second"
git -C "$WORK_DIR/first" commit --allow-empty -m 'test: next commit'
git -C "$WORK_DIR/first" push
git -C "$WORK_DIR/second" pull --ff-only
[[ "$(git -C "$WORK_DIR/first" rev-parse HEAD)" == "$(git -C "$WORK_DIR/second" rev-parse HEAD)" ]]
git -C "$WORK_DIR/second" fsck --full
STAGED="$WORK_DIR/staged"
INSTALLED="$WORK_DIR/installed"
mkdir "$STAGED"
printf 'previous\n' > "$STAGED/version"
/usr/bin/swift "$ROOT_DIR/script/InstallBundledGit.swift" "$STAGED" "$INSTALLED"
if /usr/bin/swift "$ROOT_DIR/script/InstallBundledGit.swift" "$STAGED" "$INSTALLED" 2>/dev/null; then
	printf 'Installing a missing runtime unexpectedly succeeded.\n' >&2
	exit 1
fi
[[ "$(< "$INSTALLED/version")" == previous ]]
mkdir "$STAGED"
printf 'replacement\n' > "$STAGED/version"
/usr/bin/swift "$ROOT_DIR/script/InstallBundledGit.swift" "$STAGED" "$INSTALLED"
[[ "$(< "$INSTALLED/version")" == replacement ]]
[[ "$(< "$STAGED/version")" == previous ]]
printf 'Bundled Git smoke test passed.\n'
