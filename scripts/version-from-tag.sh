#!/usr/bin/env bash
# Compute a NuGet package version from a git tag ref.
#
# Usage (in the pipeline, BUILD_SOURCEBRANCH is set by Azure DevOps):
#   bash scripts/version-from-tag.sh
#
# Usage (locally, for testing):
#   bash scripts/version-from-tag.sh refs/tags/v1.2.3
#
# Rules:
#   refs/tags/v1.2.3        -> 1.2.3
#   refs/tags/v2.0.0-beta.1 -> 2.0.0-beta.1
#   anything else           -> 0.1.0-ci.<build-number>
#     (build-number comes from BUILD_BUILDNUMBER, defaulting to 0)
#
# The version is printed on stdout. The pipeline step that calls this
# script turns it into the `packageVersion` pipeline variable.
set -euo pipefail

ref="${1:-${BUILD_SOURCEBRANCH:-}}"
build_number="${BUILD_BUILDNUMBER:-0}"

if [[ "$ref" =~ ^refs/tags/v(.+)$ ]]; then
  candidate="${BASH_REMATCH[1]}"
  # Semantic versioning: X.Y.Z with an optional -prerelease suffix.
  if [[ "$candidate" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$ ]]; then
    echo "$candidate"
    exit 0
  fi
fi

echo "0.1.0-ci.${build_number}"
