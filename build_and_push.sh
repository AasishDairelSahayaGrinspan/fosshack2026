#!/bin/bash
# ─────────────────────────────────────────────────────
# Unravel Mental Wellness App - Build & Push Script
# Generates app icon, builds release APK, pushes to branch
# ─────────────────────────────────────────────────────
set -e

cd "$(dirname "$0")"
echo "📁 Working directory: $(pwd)"

# ─── Step 1: Generate App Icon ───
echo ""
echo "🎨 Step 1: Generating app icon..."
pip install Pillow --quiet 2>/dev/null || pip3 install Pillow --quiet 2>/dev/null
python3 generate_icon.py

# ─── Step 2: Install Flutter dependencies ───
echo ""
echo "📦 Step 2: Installing Flutter dependencies..."
flutter pub get

# ─── Step 3: Apply icon to all platforms ───
echo ""
echo "🖼️  Step 3: Applying app icon to all platforms..."
dart run flutter_launcher_icons

# ─── Step 4: Build Release APK ───
echo ""
echo "🔨 Step 4: Building release APK..."
flutter build apk --release

echo ""
echo "✅ Release APK built successfully!"
echo "📍 Location: build/app/outputs/flutter-apk/app-release.apk"
APK_SIZE=$(du -h build/app/outputs/flutter-apk/app-release.apk | cut -f1)
echo "📏 Size: $APK_SIZE"

# ─── Step 5: Push to separate branch ───
echo ""
echo "🌿 Step 5: Pushing to branch 'release/v1.0.0'..."
BRANCH_NAME="release/v1.0.0"

# Save current branch
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "main")

# Create and switch to release branch
git checkout -B "$BRANCH_NAME"

# Stage all changes
git add -A

# Commit
git commit -m "release: v1.0.0 - Build release APK with custom app icon

- Added custom Unravel app icon (lavender/peach gradient with spiral)
- Configured flutter_launcher_icons for Android, iOS, and Web
- Built release APK
- Added icon generation script" --allow-empty

# Push to remote
git push -u origin "$BRANCH_NAME" --force

echo ""
echo "✅ All done!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📱 APK: build/app/outputs/flutter-apk/app-release.apk"
echo "🌿 Branch: $BRANCH_NAME"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

