# Google OAuth Web Redirect Fix - Implementation Guide

## Problem
After Google OAuth authentication on web, the app was not redirecting back to the Unravel website. Users would authenticate with Google but remain on Google's authorization screen with no redirect back to the app.

## Root Cause
The `createOAuth2Session()` call in `auth_service.dart` was missing required redirect URL parameters. Without these parameters, Appwrite doesn't know where to send users after OAuth authentication on web.

## Solution Overview

### 1. **Added OAuth Configuration Service** (`lib/services/oauth_config.dart`)
- Centralized configuration for OAuth redirect URLs
- Platform-aware: development vs. production domains
- Supports both web (HTTP redirect URLs) and mobile (custom URI schemes)
- **Development**: `http://localhost:5000`
- **Production**: Configure with your actual domain

### 2. **Updated Auth Service** (`lib/services/auth_service.dart`)
- Added web platform detection using `kIsWeb`
- OAuth redirects on web use `success` and `failure` parameters
- Mobile platforms continue using custom URI schemes
- **Method signature**:
  ```dart
  await _account.createOAuth2Session(
    provider: provider,
    success: OAuthConfig.successUrl,    // For web only
    failure: OAuthConfig.failureUrl,    // For web only
  );
  ```

### 3. **Enhanced Web HTML** (`web/index.html`)
- Added OAuth callback handler script
- Captures OAuth parameters from URL
- Cleans up URL after processing
- Stores callback data for Flutter to retrieve

### 4. **Updated Login Screen** (`lib/screens/login_screen.dart`)
- Added `initState` to detect OAuth callbacks
- Checks for authenticated session after redirect
- Auto-completes login flow on web
- Smooth transition to home/onboarding screen

### 5. **Updated Appwrite Service** (`lib/services/appwrite_service.dart`)
- Added platform-specific initialization
- Comments for future CORS configuration needs
- Ready for web domain setup

## Configuration Instructions

### For Development
The default development configuration uses `http://localhost:5000`. When running on web:
```bash
flutter run -d chrome --web-port=5000
```

### For Production
Update `lib/services/oauth_config.dart`:
```dart
static const String _prodDomain = 'https://your-actual-domain.com';
```

### Appwrite Console Setup
In Appwrite console, configure OAuth providers with these redirect URIs:
- **Success**: `https://your-domain.com/auth/success` (or `http://localhost:5000/auth/success` for dev)
- **Failure**: `https://your-domain.com/auth/error` (or `http://localhost:5000/auth/error` for dev)

## Files Modified

1. ✅ `lib/services/auth_service.dart` - Added web redirect URLs
2. ✅ `lib/services/appwrite_service.dart` - Added platform-specific config
3. ✅ `lib/screens/login_screen.dart` - Added OAuth callback detection
4. ✅ `web/index.html` - Added OAuth callback handler
5. ✨ `lib/services/oauth_config.dart` - New configuration service
6. ✨ `lib/services/oauth_web_handler.dart` - New web handler utility

## Testing Checklist

- [ ] Run Flutter analyzer: `flutter analyze` (should pass)
- [ ] Test Google OAuth on web locally at `http://localhost:5000`
- [ ] Verify redirect happens after Google authentication
- [ ] Check user is taken to home screen or onboarding
- [ ] Test on mobile (iOS/Android) - should use existing URI schemes
- [ ] Verify error handling if OAuth fails
- [ ] Test production build with actual domain

## Technical Details

### OAuth Flow on Web
1. User clicks "Continue with Google"
2. App calls `createOAuth2Session(success: successUrl, failure: failureUrl)`
3. Browser opens OAuth authorization page
4. User authorizes app with Google
5. Google redirects to `successUrl` (or `failureUrl` if denied)
6. `web/index.html` OAuth handler captures the response
7. App's `isLoggedIn()` check succeeds
8. User is redirected to home/onboarding screen

### OAuth Flow on Mobile
1. User clicks "Continue with Google"
2. App calls `createOAuth2Session(provider)` (no redirect URLs)
3. Native code handles OAuth via custom URI scheme
4. App receives callback through URI scheme
5. Session is established
6. User is redirected to home/onboarding screen

## Debugging

If OAuth redirect isn't working:

1. **Check browser console** for OAuth callback logs:
   ```javascript
   console.log('[OAuth Callback]', { ... })
   ```

2. **Verify Appwrite console settings**:
   - OAuth provider configured
   - Redirect URIs match exactly
   - Project ID matches `appwrite_constants.dart`

3. **Check auth service logs**:
   - Run `flutter run -d chrome --web-renderer html`
   - Look for `oAuthLogin` log messages

4. **Verify network requests**:
   - Open DevTools Network tab
   - Check if redirect to success URL happens
   - Verify no CORS errors

## Future Enhancements

- [ ] Add OAuth scopes parameter for granular permissions
- [ ] Implement logout and token refresh
- [ ] Add Apple OAuth support (for web)
- [ ] Implement session persistence across page reloads
- [ ] Add pre-login state validation

## Related Documentation

- Appwrite OAuth Docs: https://appwrite.io/docs/references/cloud/client-web/account#createOAuth2Session
- Flutter Web Deployment: https://flutter.dev/docs/deployment/web
