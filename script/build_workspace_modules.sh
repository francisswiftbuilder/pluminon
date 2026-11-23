#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 || ( "$1" != "Debug" && "$1" != "Release" ) ]]; then
	printf 'usage: %s <Debug|Release>\n' "$0" >&2
	exit 2
fi

CONFIGURATION="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DESTINATION='platform=macOS'

if [[ "$CONFIGURATION" == "Release" ]]; then
	DESTINATION='generic/platform=macOS'
fi

SCHEMES=(
	DomainGit
	CoreGitCredential
	CoreRepositoryUI
	CoreRepositoryDiff
	DataGit
	FeatureRepositoryChanges
	FeatureRepositoryHistory
	FeatureRepositoryOperations
	FeatureRepositoryStashes
	FeatureRepositoryTree
)

for SCHEME in "${SCHEMES[@]}"; do
	xcodebuild build \
		-workspace "$ROOT_DIR/Pluminon.xcworkspace" \
		-scheme "$SCHEME" \
		-configuration "$CONFIGURATION" \
		-destination "$DESTINATION" \
		CODE_SIGNING_ALLOWED=NO \
		COMPILER_INDEX_STORE_ENABLE=NO \
		ENABLE_USER_SCRIPT_SANDBOXING=NO
done
