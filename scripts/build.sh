#!/bin/bash
set -e
echo "Building AI-Translate..."

xcodebuild \
  -project AI-Translate.xcodeproj \
  -scheme AI-Translate \
  -configuration Release \
  CODE_SIGNING_ALLOWED=NO \
  -derivedDataPath build/DerivedData \
  build

APP_PATH=$(find build/DerivedData/Build/Products/Release-iphoneos -name "AI-Translate.app" | head -1)
if [ -z "$APP_PATH" ]; then
  echo "ERROR: .app not found"
  exit 1
fi

mkdir -p build/Payload
cp -R "$APP_PATH" build/Payload/
cd build && zip -r AI-Translate.ipa Payload/
mv AI-Translate.ipa ..
echo "IPA built: $(pwd)/AI-Translate.ipa"
