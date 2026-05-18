#!/bin/zsh

set -euo pipefail

cd "$(dirname "$0")/.."

src_rgba="assets/branding/app_icon_master.rgba.png"
src_rgb="assets/branding/app_icon_master.png"
ios_dest="ios/Runner/Assets.xcassets/AppIcon.appiconset"
mac_dest="macos/Runner/Assets.xcassets/AppIcon.appiconset"

mkdir -p assets/branding .swift-module-cache

swift -module-cache-path .swift-module-cache tool/generate_app_icon.swift "$src_rgba"
ffmpeg -y -i "$src_rgba" -frames:v 1 -update 1 -pix_fmt rgb24 "$src_rgb" >/dev/null 2>&1

cp "$src_rgb" "$ios_dest/Icon-App-1024x1024@1x.png"

for spec in \
  '20 Icon-App-20x20@1x.png' \
  '40 Icon-App-20x20@2x.png' \
  '60 Icon-App-20x20@3x.png' \
  '29 Icon-App-29x29@1x.png' \
  '58 Icon-App-29x29@2x.png' \
  '87 Icon-App-29x29@3x.png' \
  '40 Icon-App-40x40@1x.png' \
  '80 Icon-App-40x40@2x.png' \
  '120 Icon-App-40x40@3x.png' \
  '120 Icon-App-60x60@2x.png' \
  '180 Icon-App-60x60@3x.png' \
  '76 Icon-App-76x76@1x.png' \
  '152 Icon-App-76x76@2x.png' \
  '167 Icon-App-83.5x83.5@2x.png'
do
  size=${spec%% *}
  file=${spec#* }
  sips -z "$size" "$size" "$src_rgb" --out "$ios_dest/$file" >/dev/null
done

for spec in \
  '16 app_icon_16.png' \
  '32 app_icon_32.png' \
  '64 app_icon_64.png' \
  '128 app_icon_128.png' \
  '256 app_icon_256.png' \
  '512 app_icon_512.png' \
  '1024 app_icon_1024.png'
do
  size=${spec%% *}
  file=${spec#* }
  sips -z "$size" "$size" "$src_rgb" --out "$mac_dest/$file" >/dev/null
done

ffprobe -v error -select_streams v:0 -show_entries stream=width,height,pix_fmt -of default=noprint_wrappers=1 "$src_rgb"
