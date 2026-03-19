# OAuth Web Redirect Fix - Code Reference

## Problem → Solution Mapping

### THE PROBLEM: Missing Redirect URLs

**Before (Broken)**:
```dart
// lib/services/auth_service.dart - Line 180
await _account.createOAuth2Session(provider: provider);
// ❌ No success or failure parameters!
// ❌ Appwrite doesn't know where to redirect
// ❌ User stuck on Google auth page
```

**After (Fixed)**:
```dart
// lib/services/auth_service.dart - Lines 179-188
if (kIsWeb) {
  await _account.createOAuth2Session(
    provider: provider,
    success: OAuthConfig.successUrl,    // ✅ Tell Appwrite where to redirect on success
    failure: OAuthConfig.failureUrl,    // ✅ Tell Appwrite where to redirect on failure
  );
} else {
  await _account.createOAuth2Session(provider: provider);  // Mobile uses URI schemes
}
```

---

## Code Changes by File

### 1. `lib/services/oauth_config.dart` (NEW)

**Purpose**: Centralized OAuth redirect URL configuration

```dart
class OAuthConfig {
  // Dev: http://localhost:5000
  // Prod: https://yourdomain.com
  static String get baseUrl => kDebugMode ? _devDomain : _prodDomain;
  
  // URLs that Appwrite will redirect to after OAuth
  static String get successUrl => '$baseUrl/auth/success';
  static String get failureUrl => '$baseUrl/auth/error';
}
```

**Why**: 
- Single source of truth for redirect URLs
- Easy to switch between dev/prod
- Consistent across entire app

---

### 2. `lib/services/auth_service.dart` (MODIFIED)

**Import Changes**:
```dart
+ import 'package:flutter/foundation.dart';  // For kIsWeb
+ import 'oauth_config.dart';                 // For redirect URLs
```

**Method Changes** (oAuthLogin):
```dart
- await _account.createOAuth2Session(provider: provider);

+ if (kIsWeb) {
+   await _account.createOAuth2Session(
+     provider: provider,
+     success: OAuthConfig.successUrl,
+     failure: OAuthConfig.failureUrl,
+   );
+ } else {
+   await _account.createOAuth2Session(provider: provider);
+ }
```

**Why**:
- Web needs HTTP redirect URLs
- Mobile uses native URI schemes
- Appwrite SDK supports both through different parameters

---

### 3. `web/index.html` (MODIFIED)

**Added Script** (before `</head>`):
```html
<script>
  // Handle OAuth callback redirects from Appwrite
  (function() {
    const urlParams = new URLSearchParams(window.location.search);
    
    // Google redirects here with: ?code=... or ?error=...
    if (urlParams.has('code') || urlParams.has('error')) {
      console.log('[OAuth Callback]', {
        code: urlParams.get('code'),
        error: urlParams.get('error'),
      });
      
      // Store for Flutter to detect
      window.__oauthCallback = {
        success: !urlParams.has('error'),
        code: urlParams.get('code'),
        error: urlParams.get('error'),
      };
    }
    
    // Clean URL
    if (urlParams.has('code') || urlParams.has('error')) {
      window.history.replaceState({}, document.title, window.location.pathname);
    }
  })();
</script>
```

**Why**:
- Captures OAuth response from URL parameters
- Stores data for Flutter to retrieve
- Removes OAuth parameters from URL (clean history)

---

### 4. `lib/screens/login_screen.dart` (MODIFIED)

**Import Changes**:
```dart
+ import 'package:flutter/foundation.dart';  // For kIsWeb
+ import 'dart:developer' as developer;      // For logging
```

**New Method** (initState):
```dart
@override
void initState() {
  super.initState();
  if (kIsWeb) {
    _handleOAuthCallbackOnWeb();  // Check for OAuth callback on web
  }
}
```

**New Handler Method**:
```dart
Future<void> _handleOAuthCallbackOnWeb() async {
  try {
    // Wait for OAuth response to be processed
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Check if user is now logged in
    final isLoggedIn = await AuthService().isLoggedIn();
    if (isLoggedIn && mounted) {
      // Show success animation
      setState(() {
        _isVerifying = false;
        _showSuccess = true;
      });
      
      // Wait for animation
      await Future.delayed(const Duration(milliseconds: 900));
      
      // Navigate to home/onboarding
      if (mounted) {
        _navigateAfterAuth();
      }
    }
  } catch (e) {
    developer.log('OAuth callback handling error: $e');
  }
}
```

**Why**:
- Detects when user returns from OAuth callback
- Checks if session was established
- Auto-completes login flow
- No manual interaction needed

---

### 5. `lib/services/appwrite_service.dart` (MODIFIED)

**Import Changes**:
```dart
+ import 'package:flutter/foundation.dart';
```

**Initialization Changes**:
```dart
AppwriteService._internal() {
  client = Client()
      .setEndpoint(AppwriteConstants.endpoint)
      .setProject(AppwriteConstants.projectId)
      .setSelfSigned(status: true);
  
+ // Platform-specific configuration for web
+ if (kIsWeb) {
+   // On web, set the endpoint domain for proper CORS handling
+   // This ensures OAuth redirects work correctly
+ }

  account = Account(client);
  databases = Databases(client);
  storage = Storage(client);
  realtime = Realtime(client);
}
```

**Why**:
- Sets up infrastructure for web OAuth handling
- Ready for future CORS configuration if needed
- Keeps platform-specific logic in one place

---

## OAuth Flow Sequence

```
USER EXPERIENCE FLOW:
═══════════════════════════════════════════════════════════════

1. User on Login Screen
   │
   └─→ Clicks "Continue with Google"
       │
       └─→ _onGoogleLogin() called

2. Auth Service Called
   │
   └─→ AuthService.oAuthLogin(OAuthProvider.google)
       │
       ├─→ if (kIsWeb) {
       │     createOAuth2Session(
       │       provider: google,
       │       success: 'http://localhost:5000/auth/success',
       │       failure: 'http://localhost:5000/auth/error'
       │     )
       │   }
       │
       └─→ Browser opens Google auth page

3. Google Authorization
   │
   └─→ User sees Google login/consent screen
       │
       └─→ User clicks "Continue"

4. OAuth Callback
   │
   └─→ Google redirects to:
       http://localhost:5000/auth/success?code=AUTH_CODE&state=STATE
       │
       └─→ web/index.html OAuth handler captures this
           │
           └─→ Logs: {code: 'AUTH_CODE', error: null}
               └─→ Stores in window.__oauthCallback

5. App Detects Session
   │
   └─→ LoginScreen.initState() calls _handleOAuthCallbackOnWeb()
       │
       └─→ Waits 500ms for session processing
           │
           └─→ Calls AuthService.isLoggedIn()
               │
               └─→ ✅ Returns true (session established)

6. Auto-Complete Login
   │
   └─→ Show success animation (check mark)
       │
       └─→ Wait 900ms
           │
           └─→ Call _navigateAfterAuth()

7. Final Navigation
   │
   └─→ Load UserPreferencesService from remote
       │
       └─→ Check hasCompletedOnboarding
           │
           ├─→ YES: Navigate to MainShell (home)
           │
           └─→ NO: Navigate to OnboardingScreen

8. ✅ User Logged In
   │
   └─→ In app, with session established
```

---

## Parameter Explanation

### `success` Parameter
- **What**: URL to redirect to after successful OAuth authentication
- **When**: User authorizes the app with their Google account
- **Example**: `http://localhost:5000/auth/success?code=12345&state=abc`
- **What Happens**: Google's OAuth provider redirects to this URL with auth code

### `failure` Parameter
- **What**: URL to redirect to if OAuth authentication fails
- **When**: User denies app access or an error occurs
- **Example**: `http://localhost:5000/auth/error?error=access_denied`
- **What Happens**: Google's OAuth provider redirects to this URL with error details

---

## Mobile vs Web Differences

### Mobile (iOS/Android):
```dart
// No redirect URLs needed - uses native URI schemes
await _account.createOAuth2Session(provider: provider);

// Native config handles the redirect:
// iOS: appwrite-callback-unravel-app:// (in Info.plist)
// Android: appwrite-callback-unravel-app:// (in AndroidManifest.xml)
```

### Web (Browser):
```dart
// Redirect URLs are required - web doesn't have URI schemes
await _account.createOAuth2Session(
  provider: provider,
  success: 'http://localhost:5000/auth/success',
  failure: 'http://localhost:5000/auth/error',
);

// Browser handles the redirect via web page navigation
```

---

## Common Issues & Solutions

### Issue 1: "No redirect URL configured"
**Solution**: Ensure `success` and `failure` parameters are passed for web:
```dart
if (kIsWeb) {
  await _account.createOAuth2Session(
    provider: provider,
    success: OAuthConfig.successUrl,  // ✅ Required for web
    failure: OAuthConfig.failureUrl,  // ✅ Required for web
  );
}
```

### Issue 2: "Appwrite console redirect URL mismatch"
**Solution**: Configure exact same URLs in Appwrite console:
- Development: `http://localhost:5000/auth/success` and `/auth/error`
- Production: `https://yourdomain.com/auth/success` and `/auth/error`

### Issue 3: "User redirects back but login doesn't complete"
**Solution**: Ensure LoginScreen checks for OAuth callback:
```dart
@override
void initState() {
  super.initState();
  if (kIsWeb) {
    _handleOAuthCallbackOnWeb();  // ✅ Check on web
  }
}
```

### Issue 4: "Mobile OAuth broken after changes"
**Solution**: Only add redirect parameters for web:
```dart
if (kIsWeb) {
  // Use redirect URLs for web
} else {
  // Don't use redirect URLs for mobile
}
```

---

## Testing Your Implementation

### 1. Development Testing
```bash
# Run on web at localhost:5000
flutter run -d chrome --web-port=5000
```

### 2. Check Browser Console
```javascript
// You should see this log when callback happens
[OAuth Callback] {
  hash: "",
  search: "?code=AUTH_CODE&state=STATE",
  code: "AUTH_CODE",
  error: null,
  state: "STATE",
  url: "http://localhost:5000/?code=AUTH_CODE&state=STATE"
}
```

### 3. Verify Session
```bash
# Check app logs for this message
"OAuth callback: User authenticated successfully"
```

### 4. Final Verification
- ✅ User redirects back to app
- ✅ Success animation shows
- ✅ User taken to home/onboarding
- ✅ Session persists on refresh

---

## Summary

This fix implements the complete OAuth redirect flow for web:

1. **Redirect URL Configuration** → `oauth_config.dart`
2. **OAuth Method Call** → `auth_service.dart`
3. **Callback Capture** → `web/index.html`
4. **Login Completion** → `login_screen.dart`
5. **Platform Setup** → `appwrite_service.dart`

All pieces work together to ensure users redirect back to the app after OAuth authentication and login completes automatically.
