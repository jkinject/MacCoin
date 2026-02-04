#!/bin/bash
set -e

SIGN_IDENTITY="Developer ID Application: Young suk Lee (Z6W6BC2L2L)"
TEAM_ID="Z6W6BC2L2L"
ARCHIVE_PATH="build/MacCoin.xcarchive"
EXPORT_PATH="build/export"
ZIP_PATH="build/MacCoin.app.zip"

echo "🧹 이전 빌드 정리 중..."
rm -rf "$ARCHIVE_PATH" "$EXPORT_PATH" "$ZIP_PATH"

echo "🔨 MacCoin 아카이브 빌드 중..."
xcodebuild archive \
  -project MacCoin.xcodeproj \
  -scheme MacCoin \
  -configuration Release \
  -archivePath "$ARCHIVE_PATH" \
  CODE_SIGN_IDENTITY="$SIGN_IDENTITY" \
  DEVELOPMENT_TEAM="$TEAM_ID" \
  CODE_SIGN_STYLE=Manual \
  ENABLE_HARDENED_RUNTIME=YES

APP_PATH="$ARCHIVE_PATH/Products/Applications/MacCoin.app"

echo ""
echo "🔏 서명 확인 중..."
codesign --verify --verbose "$APP_PATH"

echo ""
echo "📦 배포용 ZIP 생성 중..."
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ZIP_PATH"

echo ""
echo "✅ 빌드 완료!"
echo "   앱: $APP_PATH"
echo "   ZIP: $ZIP_PATH"
echo ""
echo "Applications 폴더로 복사하려면:"
echo "  cp -R \"$APP_PATH\" /Applications/"
echo ""
echo "바로 실행하려면:"
echo "  open \"$APP_PATH\""
