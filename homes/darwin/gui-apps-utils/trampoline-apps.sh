#!/usr/bin/env bash
# https://github.com/nix-community/home-manager/issues/1341#issuecomment-1870352014

# Utilities not in nixpkgs.
plutil="/usr/bin/plutil"
osacompile="/usr/bin/osacompile"

copyable_app_props=(
  "CFBundleDevelopmentRegion"
  "CFBundleDocumentTypes"
  "CFBundleGetInfoString"
  "CFBundleIconFile"
  "CFBundleIdentifier"
  "CFBundleInfoDictionaryVersion"
  "CFBundleName"
  "CFBundleShortVersionString"
  "CFBundleURLTypes"
  "NSAppleEventsUsageDescription"
  "NSAppleScriptEnabled"
  "NSDesktopFolderUsageDescription"
  "NSDocumentsFolderUsageDescription"
  "NSDownloadsFolderUsageDescription"
  "NSPrincipalClass"
  "NSRemovableVolumesUsageDescription"
  "NSServices"
  "UTExportedTypeDeclarations"
)

function sync_icons() {
  local from="$1"
  local to="$2"
  from_resources="$from/Contents/Resources/"
  to_resources="$to/Contents/Resources/"

  find "$to_resources" -name "*.icns" -delete
  rsync --include "*.icns" --exclude "*" --recursive "$from_resources" "$to_resources"
}

function copy_paths() {
  local from="$1"
  local to="$2"
  local paths=("${@:3}")

  keys=$(jq -n '$ARGS.positional' --args "${paths[@]}")
  # shellcheck disable=SC2016
  jqfilter='to_entries |[.[]| select(.key as $item| $keys | index($item) >= 0) ] | from_entries'

  temp_dir=$(mktemp -d)
  trap 'rm -rf "$temp_dir"' EXIT

  pushd "$temp_dir" >/dev/null || exit

  cp "$from" "orig"
  chmod u+w "orig"

  cp "$to" "bare-wrapper"
  chmod u+w "bare-wrapper"

  $plutil -convert json -- "orig"
  $plutil -convert json -- "bare-wrapper"
  jq --argjson keys "$keys" "$jqfilter" <"orig" >"filtered"
  cat "bare-wrapper" "filtered" | jq -s add >"final"
  $plutil -convert xml1 -- "final"

  cp "final" "$to"
  popd >/dev/null || exit
}

function mktrampoline() {
  local app="$1"
  local trampoline="$2"

  if [[ ! -d $app ]]; then
    echo "app path is not directory."
    return 1
  fi

  cmd="do shell script \"open '$app'\""
  $osacompile -o "$trampoline" -e "$cmd"
  sync_icons "$app" "$trampoline"
  copy_paths "$(realpath "$app/Contents/Info.plist")" "$(realpath "$trampoline/Contents/Info.plist")" "${copyable_app_props[@]}"
}

function sync_trampolines() {
  [[ ! -d $1 ]] && echo "Source directory does not exist" && return 1

  if [[ -d $2 ]]; then
    rm -rf "$2"
  fi
  mkdir -p "$2"

  apps=("$1"/*.app)

  for app in "${apps[@]}"; do
    trampoline="$2/$(basename "$app")"
    mktrampoline "$app" "$trampoline"
  done
}
