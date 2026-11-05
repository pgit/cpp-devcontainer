#!/bin/bash
#
# Compare the versions pinned in the Dockerfile with the latest upstream releases.
# Needs curl, jq, xz and git. Set GITHUB_TOKEN to avoid GitHub API rate limits.
#
set -euo pipefail

DOCKERFILE="$(dirname "$0")/Dockerfile"

pinned() {
    grep -E "^ARG $1=" "$DOCKERFILE" | head -1 | cut -d= -f2
}

gh_latest() {
    curl -fsSL ${GITHUB_TOKEN:+-H "Authorization: Bearer $GITHUB_TOKEN"} \
        "https://api.github.com/repos/$1/releases/latest" | jq -r .tag_name
}

report() {
    local status="ok"
    [ "$2" != "$3" ] && status="UPDATE"
    printf "%-15s %-42s %-42s %s\n" "$1" "$2" "$3" "$status"
}

printf "%-15s %-42s %-42s %s\n" "ARG" "pinned" "latest" ""

# Debian stable codename
VARIANT=$(pinned VARIANT)
report VARIANT "$VARIANT" \
    "$(curl -fsSL https://deb.debian.org/debian/dists/stable/Release | sed -n 's/^Codename: //p')"

# LLVM: latest stable major (apt.llvm.org stable branch == latest GitHub release)
report LLVM_VERSION "$(pinned LLVM_VERSION)" \
    "$(gh_latest llvm/llvm-project | sed -E 's/^llvmorg-([0-9]+)\..*/\1/')"

# GCC: highest g++-N in Debian ${VARIANT} and ${VARIANT}-backports
GCC_LATEST=$(for suite in "$VARIANT" "$VARIANT-backports"; do
        curl -fsSL "https://deb.debian.org/debian/dists/$suite/main/binary-amd64/Packages.xz" | xz -dc
    done | sed -nE 's/^Package: g\+\+-([0-9]+)$/\1/p' | sort -n | tail -1)
report GCC_VERSION "$(pinned GCC_VERSION)" "$GCC_LATEST"

report BV "$(pinned BV)" "$(gh_latest boostorg/boost | sed 's/^boost-//')"
report CMAKE_VERSION "$(pinned CMAKE_VERSION)" "$(gh_latest Kitware/CMake | sed 's/^v//')"
report FMT_VERSION "$(pinned FMT_VERSION)" "$(gh_latest fmtlib/fmt)"

# spdlog is pinned by commit; resolve the latest release tag to its commit
SPDLOG_TAG=$(gh_latest gabime/spdlog)
SPDLOG_SHA=$(git ls-remote https://github.com/gabime/spdlog.git "refs/tags/$SPDLOG_TAG^{}" "refs/tags/$SPDLOG_TAG" \
    | sort -k2 -r | head -1 | cut -f1)
report SPDLOG_COMMIT "$(pinned SPDLOG_COMMIT)" "$SPDLOG_SHA"
echo "                (latest spdlog release: $SPDLOG_TAG)"
