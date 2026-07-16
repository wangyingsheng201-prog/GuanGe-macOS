#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$ROOT/.build-universal"
STAGE="$WORK/观格-macOS-1.0.0"
APP="$STAGE/观格.app"
CONTENTS="$APP/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"
DIST="$ROOT/dist"

rm -rf "$WORK" "$DIST"
mkdir -p "$MACOS" "$RESOURCES" "$DIST"

echo "[1/6] 编译 Apple Silicon 版本"
swift build \
  --package-path "$ROOT" \
  --scratch-path "$WORK/build-arm64" \
  -c release \
  --arch arm64
ARM_BIN_DIR="$(swift build --package-path "$ROOT" --scratch-path "$WORK/build-arm64" -c release --arch arm64 --show-bin-path)"

echo "[2/6] 编译 Intel 版本"
swift build \
  --package-path "$ROOT" \
  --scratch-path "$WORK/build-x86_64" \
  -c release \
  --arch x86_64
X86_BIN_DIR="$(swift build --package-path "$ROOT" --scratch-path "$WORK/build-x86_64" -c release --arch x86_64 --show-bin-path)"

echo "[3/6] 合并为 Universal 2 可执行文件"
lipo -create "$ARM_BIN_DIR/GuanGe" "$X86_BIN_DIR/GuanGe" -output "$MACOS/GuanGe"
chmod +x "$MACOS/GuanGe"
lipo -info "$MACOS/GuanGe"

echo "[4/6] 组装应用程序包与图标"
cp "$ROOT/Resources/Info.plist" "$CONTENTS/Info.plist"
cp "$ROOT/Resources/guange-icon.png" "$RESOURCES/guange-icon.png"
cp "$ROOT/Resources/支付宝收款码.jpg" "$RESOURCES/支付宝收款码.jpg"
cp "$ROOT/Resources/微信打赏码.jpg" "$RESOURCES/微信打赏码.jpg"

ICONSET="$WORK/AppIcon.iconset"
mkdir -p "$ICONSET"
sips -z 16 16     "$ROOT/Resources/guange-icon.png" --out "$ICONSET/icon_16x16.png" >/dev/null
sips -z 32 32     "$ROOT/Resources/guange-icon.png" --out "$ICONSET/icon_16x16@2x.png" >/dev/null
sips -z 32 32     "$ROOT/Resources/guange-icon.png" --out "$ICONSET/icon_32x32.png" >/dev/null
sips -z 64 64     "$ROOT/Resources/guange-icon.png" --out "$ICONSET/icon_32x32@2x.png" >/dev/null
sips -z 128 128   "$ROOT/Resources/guange-icon.png" --out "$ICONSET/icon_128x128.png" >/dev/null
sips -z 256 256   "$ROOT/Resources/guange-icon.png" --out "$ICONSET/icon_128x128@2x.png" >/dev/null
sips -z 256 256   "$ROOT/Resources/guange-icon.png" --out "$ICONSET/icon_256x256.png" >/dev/null
sips -z 512 512   "$ROOT/Resources/guange-icon.png" --out "$ICONSET/icon_256x256@2x.png" >/dev/null
sips -z 512 512   "$ROOT/Resources/guange-icon.png" --out "$ICONSET/icon_512x512.png" >/dev/null
cp "$ROOT/Resources/guange-icon.png" "$ICONSET/icon_512x512@2x.png"
iconutil -c icns "$ICONSET" -o "$RESOURCES/AppIcon.icns"

echo "[5/6] 临时签名并加入说明文件"
codesign --force --deep --sign - "$APP"
cp "$ROOT/macOS-操作使用说明.txt" "$STAGE/macOS-操作使用说明.txt"
cp "$ROOT/macOS-版本更新日志.txt" "$STAGE/macOS-版本更新日志.txt"
cp "$ROOT/首次运行.command" "$STAGE/首次运行.command"
chmod +x "$STAGE/首次运行.command"

echo "[6/6] 打包"
ditto -c -k --sequesterRsrc --keepParent "$STAGE" "$DIST/GuanGe-macOS-Universal-1.0.0.zip"
echo "完成：$DIST/GuanGe-macOS-Universal-1.0.0.zip"
