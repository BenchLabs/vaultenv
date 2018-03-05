#!/bin/bash

# This script builds a .deb package from the binaries in the .stack-work
# directory.
#
#   Usage: ./scripts/build_package.sh

# Safe scripting options:
#  - `e` for fail on nonzero exit of any command
#  - `u` for fail on unset variables
#  - `f` to disable globbing
#  - `o pipefail` for error on failed pipes
set -euf -o pipefail

# Change to the parent directory of this script
cd "$(dirname "$0")/.."

stack setup --install-ghc --allow-different-user

# Get the package version from Stack, eliminate the single quotes.
# Exported, because it is used with envsubst to write the control file.
export VERSION=$(stack --allow-different-user query locals vaultenv version | sed -e "s/^'//" -e "s/'$//")

# The name of the .deb file to create
PKGNAME="vaultenv-${VERSION}"

# Recreate the file system layout as it should be on the target machine.
mkdir -p "$PKGNAME/DEBIAN"
mkdir -p "$PKGNAME/usr/bin"
mkdir -p "$PKGNAME/etc/secrets.d"

stack build --allow-different-user
stack install --allow-different-user
cp "$(stack path --allow-different-user --local-install-root)/bin/vaultenv" "$PKGNAME/usr/bin/"

# Write the package metadata file, substituting environment variables in the
# template file.
cat package/deb_control | envsubst > "$PKGNAME/DEBIAN/control"

# Build the Debian package
dpkg-deb --build "$PKGNAME"

# Clean up temporary files
rm -fr "$PKGNAME"
