#!/bin/sh

set -eu

IOS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_DIR="$(cd "${IOS_DIR}/.." && pwd)"
PUBSPEC_PATH="${PROJECT_DIR}/pubspec.yaml"
GENERATED_XCCONFIG_PATH="${IOS_DIR}/Flutter/Generated.xcconfig"
EXPORT_ENV_PATH="${IOS_DIR}/Flutter/flutter_export_environment.sh"

VERSION_LINE="$(grep '^version:' "${PUBSPEC_PATH}" | head -n 1 | cut -d':' -f2- | xargs)"

if [ -z "${VERSION_LINE}" ]; then
  echo "error: Could not resolve version from ${PUBSPEC_PATH}" >&2
  exit 1
fi

APP_VERSION="${VERSION_LINE%%+*}"
BUILD_NUMBER="${VERSION_LINE#*+}"

if [ "${BUILD_NUMBER}" = "${VERSION_LINE}" ]; then
  BUILD_NUMBER="1"
fi

update_file_value() {
  file_path="$1"
  pattern="$2"
  replacement="$3"

  if [ ! -f "${file_path}" ]; then
    return
  fi

  tmp_file="$(mktemp)"
  awk -v pattern="${pattern}" -v replacement="${replacement}" '
    index($0, pattern) == 1 {
      print replacement
      next
    }
    { print }
  ' "${file_path}" > "${tmp_file}"
  mv "${tmp_file}" "${file_path}"
}

update_file_value \
  "${GENERATED_XCCONFIG_PATH}" \
  "FLUTTER_BUILD_NAME=" \
  "FLUTTER_BUILD_NAME=${APP_VERSION}"
update_file_value \
  "${GENERATED_XCCONFIG_PATH}" \
  "FLUTTER_BUILD_NUMBER=" \
  "FLUTTER_BUILD_NUMBER=${BUILD_NUMBER}"

update_file_value \
  "${EXPORT_ENV_PATH}" \
  "export \"FLUTTER_BUILD_NAME=" \
  "export \"FLUTTER_BUILD_NAME=${APP_VERSION}\""
update_file_value \
  "${EXPORT_ENV_PATH}" \
  "export \"FLUTTER_BUILD_NUMBER=" \
  "export \"FLUTTER_BUILD_NUMBER=${BUILD_NUMBER}\""

if [ -n "${TARGET_BUILD_DIR:-}" ] && [ -n "${INFOPLIST_PATH:-}" ]; then
  BUILT_PLIST_PATH="${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"

  if [ -f "${BUILT_PLIST_PATH}" ]; then
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${APP_VERSION}" "${BUILT_PLIST_PATH}" \
      || /usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string ${APP_VERSION}" "${BUILT_PLIST_PATH}"
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${BUILD_NUMBER}" "${BUILT_PLIST_PATH}" \
      || /usr/libexec/PlistBuddy -c "Add :CFBundleVersion string ${BUILD_NUMBER}" "${BUILT_PLIST_PATH}"
  fi
fi

echo "Synced pubspec version ${APP_VERSION}+${BUILD_NUMBER}"
