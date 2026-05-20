#!/bin/zsh

set -euo pipefail

cd "$(dirname "$0")/.."

src_master="assets/branding/app_icon_master.png"
src_rgba="assets/branding/app_icon_master.rgba.png"
src_bmp="assets/branding/app_icon_master.bmp"
ios_dest="ios/Runner/Assets.xcassets/AppIcon.appiconset"
mac_dest="macos/Runner/Assets.xcassets/AppIcon.appiconset"
android_res_root="android/app/src/main/res"
web_root="web"

mkdir -p assets/branding

if [[ ! -f "$src_master" ]]; then
  echo "Missing source icon: $src_master" >&2
  exit 1
fi

sips -s format png "$src_master" --out "$src_rgba" >/dev/null
sips -s format bmp "$src_master" --out "$src_bmp" >/dev/null
sips -z 1024 1024 "$src_master" --out "$ios_dest/Icon-App-1024x1024@1x.png" >/dev/null

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
  sips -z "$size" "$size" "$src_master" --out "$ios_dest/$file" >/dev/null
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
  sips -z "$size" "$size" "$src_master" --out "$mac_dest/$file" >/dev/null
done

for spec in \
  '48 mipmap-mdpi/ic_launcher.png' \
  '72 mipmap-hdpi/ic_launcher.png' \
  '96 mipmap-xhdpi/ic_launcher.png' \
  '144 mipmap-xxhdpi/ic_launcher.png' \
  '192 mipmap-xxxhdpi/ic_launcher.png'
do
  size=${spec%% *}
  file=${spec#* }
  sips -z "$size" "$size" "$src_master" --out "$android_res_root/$file" >/dev/null
done

for spec in \
  '64 favicon.png' \
  '192 icons/Icon-192.png' \
  '192 icons/Icon-maskable-192.png' \
  '512 icons/Icon-512.png' \
  '512 icons/Icon-maskable-512.png'
do
  size=${spec%% *}
  file=${spec#* }
  sips -z "$size" "$size" "$src_master" --out "$web_root/$file" >/dev/null
done

sips -g pixelWidth -g pixelHeight "$src_master"
