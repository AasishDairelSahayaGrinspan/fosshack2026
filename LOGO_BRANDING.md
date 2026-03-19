# Unravel Logo Branding Setup

## Overview
This document describes the consistent logo branding setup across all platforms for the Unravel application.

## Primary Source Logo
- **File**: `assets/app_icon.png`
- **Size**: 640x640 pixels
- **Format**: PNG with transparency
- **Description**: Professional icon with head silhouette and colorful interconnected circles representing mental wellness and connectivity

This is the single source of truth for all platform-specific icons.

## Platform-Specific Icon Locations

### Android
**Configuration**: `flutter_launcher_icons.yaml`
- **Source**: `assets/app_icon.png`
- **Generated Icons**: `android/app/src/main/res/mipmap-{density}/`
  - `launcher_icon.png` - Main app icon
  - `ic_launcher.png` - Legacy icon
- **Adaptive Icon**: Background color `#ffffff` with app_icon.png as foreground
- **Min SDK**: API 21+
- **Regenerate**: `dart run flutter_launcher_icons`

### iOS
**Configuration**: `flutter_launcher_icons.yaml`
- **Source**: `assets/app_icon.png`
- **Generated Icons**: `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
- **Sizes**: Multiple resolutions from 20x20 to 1024x1024 at 1x, 2x, and 3x scales
- **Regenerate**: `dart run flutter_launcher_icons`

### Web
**Configuration**: 
- `web/manifest.json` - PWA manifest with icon definitions
- `web/index.html` - Favicon and Apple touch icon references

**Icons**:
- `web/favicon.png` - 192x192 (displayed in browser tab)
- `web/icons/Icon-192.png` - PWA icon for 192x192 displays
- `web/icons/Icon-512.png` - PWA icon for 512x512 displays (recommended for app install)
- `web/icons/Icon-maskable-192.png` - Adaptive icon with safe zone
- `web/icons/Icon-maskable-512.png` - Adaptive icon with safe zone

**Regenerate**: All web icons are generated from `assets/app_icon.png` using image processing

### Windows
**Icon**: `windows/runner/resources/app_icon.ico`
- Format: ICO (multi-resolution Windows icon format)
- Used for: Application icon in Windows taskbar and file explorer

### macOS
**Icons**: `macos/Runner/Assets.xcassets/AppIcon.appiconset/`
- Multiple sizes from 16x16 to 1024x1024
- Includes 1x and 2x scale variants
- Standard Xcode asset catalog format

### Linux
No platform-specific icons currently configured. Can be added if Linux support is planned.

## Branding Colors
- **Primary Theme**: `#3A86FF` (Blue - Mental clarity)
- **Adaptive Background**: `#ffffff` (White)
- **Web Background**: `#ffffff` (White)

## Configuration Files

### flutter_launcher_icons.yaml
Controls automatic icon generation for Android and iOS platforms.
```yaml
flutter_launcher_icons:
  image_path: "assets/app_icon.png"
  android: true
  ios: true
  adaptive_icon_background: "#ffffff"
  adaptive_icon_foreground: "assets/app_icon.png"
  min_sdk_android: 21
```

### web/manifest.json
PWA (Progressive Web App) configuration with icon definitions for web installation.
- Includes both standard and maskable icons
- Theme color: `#3A86FF`
- Background color: `#ffffff`

### web/index.html
- Favicon reference: `<link rel="icon" type="image/png" href="favicon.png"/>`
- Apple touch icon: `<link rel="apple-touch-icon" href="icons/Icon-192.png">`
- App description: "Unravel - A mental wellness app..."

## Maintenance Guidelines

### When to Update Logos
1. **Brand redesign**: Replace `assets/app_icon.png` with new design
2. **Icon changes**: Update `assets/app_icon.png` then regenerate all platforms

### Regenerating Icons

**For Android & iOS**:
```bash
dart run flutter_launcher_icons
```

**For Web**:
Icons are pre-generated in `web/icons/` and `web/favicon.png`. If you update the source logo:
1. Use image processing tool to resize:
   - 192x192 → Icon-192.png
   - 512x512 → Icon-512.png
   - Apply 20% padding safe zone for maskable versions

### Consolidation Note
- `assets/app_icon.png` is the primary branding icon (currently used)
- `assets/logo.png` is a legacy/alternative icon - can be kept for reference or archived
- All platform icons are derived from `app_icon.png`

## Verification Checklist
- [x] Web: favicon displays correctly in browser tab
- [x] Web: PWA install shows correct icon
- [x] iOS: App icon displays correctly in Springboard
- [x] Android: Adaptive icon displays correctly on Android 8+
- [x] Windows: Icon displays correctly in taskbar
- [x] All platforms: Consistent branding across devices

## Platform-Specific Notes

### Android Adaptive Icons
Adaptive icons on Android 8+ display:
- **Background**: `#ffffff` (white)
- **Foreground**: app_icon.png
- System may apply mask (circle, teardrop, etc.) based on device theme

### iOS Icon Scaling
iOS automatically scales the icon based on device resolution:
- iPhone 3GS-5: 57x57
- iPhone 6/7/8: 60x60
- iPhone 6/7/8 Plus: 120x120
- iPhone X+: 180x180
- iPad: 76x76 - 167x167
- App Store: 1024x1024

### Web PWA Standards
- Maskable icons enable browser to apply device-specific mask effects
- Multiple sizes ensure optimal display on different devices
- Icons should have safe zone (20% padding) for maskable variants

## Related Files
- `pubspec.yaml` - Project configuration (includes flutter_launcher_icons dependency)
- `appwrite.config.json` - Backend configuration (no branding settings)
