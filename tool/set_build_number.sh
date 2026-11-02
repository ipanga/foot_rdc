#!/bin/bash
# Sets the build number in pubspec.yaml and copies the version to the push extension, which has no Flutter settings.
# usage: tool/set_build_number.sh <number>
set -euo pipefail
cd "$(dirname "$0")/.."
BUILD=${1:?usage: tool/set_build_number.sh <number>}
[[ "$BUILD" =~ ^[0-9]+$ ]] || { echo "Build number must be a whole number"; exit 1; }
NAME=$(sed -nE 's/^version: ([0-9.]+)\+[0-9]+$/\1/p' pubspec.yaml)
sed -i '' -E "s/^version: .*/version: $NAME+$BUILD/" pubspec.yaml
sed -i '' -E "s/CURRENT_PROJECT_VERSION = [0-9]+;/CURRENT_PROJECT_VERSION = $BUILD;/; s/MARKETING_VERSION = [0-9.]+;/MARKETING_VERSION = $NAME;/" ios/Runner.xcodeproj/project.pbxproj
echo "Version $NAME+$BUILD"
