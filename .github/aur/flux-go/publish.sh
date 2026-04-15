#!/usr/bin/env bash

# Publishes the flux-go AUR package.
# This script generates the PKGBUILD and .SRCINFO files from templates,
# then pushes them to the AUR repository.
#
# Usage: publish.sh <version>
# Example: publish.sh 2.3.0

set -euo pipefail

VERSION=${1:-}

if [[ -z "${VERSION}" ]]; then
  echo "Error: version argument is required"
  echo "Usage: $0 <version>"
  exit 1
fi

# Strip leading 'v' if present
VERSION=${VERSION#v}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AUR_PACKAGE="flux-go"
AUR_REPO="ssh://aur@aur.archlinux.org/${AUR_PACKAGE}.git"
WORK_DIR=$(mktemp -d)

cleanup() {
  rm -rf "${WORK_DIR}"
}
trap cleanup EXIT

echo "Publishing ${AUR_PACKAGE} version ${VERSION} to AUR..."

# Clone the AUR repository
git clone "${AUR_REPO}" "${WORK_DIR}/${AUR_PACKAGE}"

# Generate PKGBUILD from template
sed \
  -e "s|{{VERSION}}|${VERSION}|g" \
  "${SCRIPT_DIR}/PKGBUILD.template" > "${WORK_DIR}/${AUR_PACKAGE}/PKGBUILD"

echo "Generated PKGBUILD:"
cat "${WORK_DIR}/${AUR_PACKAGE}/PKGBUILD"

# Generate .SRCINFO from template
sed \
  -e "s|{{VERSION}}|${VERSION}|g" \
  "${SCRIPT_DIR}/.SRCINFO.template" > "${WORK_DIR}/${AUR_PACKAGE}/.SRCINFO"

echo "Generated .SRCINFO:"
cat "${WORK_DIR}/${AUR_PACKAGE}/.SRCINFO"

# Commit and push to AUR
pushd "${WORK_DIR}/${AUR_PACKAGE}"

git config user.name "fluxcdbot"
git config user.email "fluxcdbot@users.noreply.github.com"

git add PKGBUILD .SRCINFO

if git diff --cached --quiet; then
  echo "No changes to commit for ${AUR_PACKAGE} version ${VERSION}"
else
  git commit -m "Update to version ${VERSION}"
  git push origin master
  echo "Successfully published ${AUR_PACKAGE} version ${VERSION} to AUR"
fi

popd
