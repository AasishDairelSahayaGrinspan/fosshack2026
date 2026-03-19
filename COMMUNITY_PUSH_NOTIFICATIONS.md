# Community Push Notifications Implementation Guide

## Overview
This implementation adds push notifications for community updates in the Unravel app. When a user posts in the community, all other users (NOT the poster) receive push notifications.

## Architecture

### Components Implemented

#### 1. **NotificationService** (`lib/services/notification_service.dart`)
- Added community notification channel
- Added `showCommunityPostNotification()` method to display local notifications
- Added `onNotificationTapped()` handler for notification interactions
- Notifications include post title excerpt and author name

#### 2. **CommunityService** (`lib/services/community_service.dart`)
- Integrated notification trigger after post creation
- Added `_sendCommunityNotification()` private method
- Added `_triggerServerNotifications()` to call Appwrite Cloud Function
- Excludes post creator from receiving notifications

#### 3. **AppwriteService** (`lib/services/appwrite_service.dart`)
- Added `Functions` module for calling Cloud Functions
- Enables serverless notification delivery

#### 4. **Appwrite Cloud Function** (`appwrite/functions/sendCommunityNotifications/`)
- Node.js function that runs server-side
- Queries all users except the post creator
- Sends Firebase Cloud Messaging (FCM) notifications
- Includes error handling and logging

## Setup Instructions

### Step 1: Enable Firebase Cloud Messaging (FCM)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project (or create one)
3. Navigate to Project Settings → Service Accounts
4. Generate a new private key (JSON format)
5. Extract the `server_key` from the downloaded JSON
6. This is your `FCM_SERVER_KEY`

### Step 2: Create Appwrite Cloud Function

1. Open your Appwrite Console
2. Go to Functions
3. Create a new function called `sendCommunityNotifications`
4. Use Node.js 18.0.0 runtime
5. Copy the code from `appwrite/functions/sendCommunityNotifications/index.js`
6. Install dependencies (the function already has `node-appwrite` in package.json)
7. Set environment variables:
   - `APPWRITE_PROJECT_ID`: Your project ID (e.g., `unravel-app`)
   - `APPWRITE_DATABASE_ID`: Your database ID (e.g., `unravel_db`)
   - `APPWRITE_USERS_COLLECTION_ID`: Your users collection ID (e.g., `users`)
   - `APPWRITE_API_KEY`: An Appwrite API key with admin permissions
   - `FCM_SERVER_KEY`: Your Firebase Cloud Messaging server key

### Step 3: Store Device Tokens

Add a `deviceTokens` field to your users collection:

```dart
// In database_service.dart or user_preferences_service.dart
// Update user document to include device tokens
await _db.updateDocument(
  databaseId: databaseId,
  collectionId: usersCollection,
  documentId: userId,
  data: {
    'deviceTokens': [...existing tokens, newToken],
  },
);
```

**Example User Document Schema:**
```json
{
  "$id": "user123",
  "name": "John Doe",
  "email": "john@example.com",
  "notificationsEnabled": true,
  "deviceTokens": [
    "fcm_token_android_device_1",
    "fcm_token_ios_device_1"
  ],
  // ... other fields
}
```

### Step 4: Integrate FCM in Flutter

Add to `pubspec.yaml`:
```yaml
firebase_messaging: ^14.0.0
```

Implement device token registration (example):
```dart
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> registerDeviceToken() async {
  try {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      // Save token to Appwrite user document
      await saveDeviceToken(token);
    }
  } catch (e) {
    developer.log('Failed to register device token', error: e);
  }
}
```

### Step 5: Update Notification Permissions

Ensure your Flutter app requests notification permissions:
- Android: Handled via `flutter_local_notifications`
- iOS: Implement in AppDelegate

## Notification Flow

### User A Posts in Community
```
1. User A opens CreatePostScreen
2. User A enters caption and submits
3. Post is created in Appwrite database
4. CommunityService.addPost() is called
5. Local notification shown to User A (showing preview)
6. _sendCommunityNotification() triggers
7. _triggerServerNotifications() calls Appwrite Cloud Function
8. Cloud Function queries all users except User A
9. Cloud Function sends FCM notification to each user's device tokens
10. Users B, C, D, etc. receive notifications
```

### Notification Content
- **Title**: "{Author Name} posted in Community"
- **Body**: Post caption (truncated to 100 chars)
- **Data Payload**:
  - `postId`: ID of the new post
  - `type`: "community_post"
  - `authorId`: ID of the post creator
  - `authorName`: Name of the post creator

### Notification Interaction
When user taps notification:
- App opens (if closed)
- `onNotificationTapped()` is called in NotificationService
- Can be extended to navigate to community post detail screen

## Testing

### Local Testing (Without FCM)

The implementation includes fallbacks:
1. If FCM is not configured, the app will still show local notifications
2. Cloud Function gracefully handles missing FCM_SERVER_KEY
3. Test locally by posting in community - local notification appears

### End-to-End Testing

1. Set up multiple test devices/emulators
2. Install app with same Appwrite credentials
3. User 1 posts in community
4. Verify User 2, 3, etc. receive notifications
5. Verify User 1 does NOT receive their own notification
6. Verify notification includes post preview

### Debugging

Check Appwrite Cloud Function logs:
1. Go to Appwrite Console → Functions
2. Select `sendCommunityNotifications`
3. View execution logs
4. Look for success/failure details

Check FCM delivery:
1. Go to Firebase Console → Cloud Messaging
2. Monitor message delivery status
3. Check for device token issues

## Files Modified

1. **lib/services/notification_service.dart**
   - Added community notification channel
   - Added `showCommunityPostNotification()` method
   - Added `onNotificationTapped()` handler

2. **lib/services/community_service.dart**
   - Added notification trigger in `addPost()`
   - Added `_sendCommunityNotification()` method
   - Added `_triggerServerNotifications()` method
   - Imported NotificationService

3. **lib/services/appwrite_service.dart**
   - Added `Functions` module

## Files Created

1. **appwrite/functions/sendCommunityNotifications/index.js**
   - Cloud Function source code
   - Handles FCM notification delivery
   - Queries users and filters out post creator

2. **appwrite/functions/sendCommunityNotifications/package.json**
   - Function dependencies
   - Node.js 18 runtime specification

3. **COMMUNITY_PUSH_NOTIFICATIONS.md** (this file)
   - Implementation guide and setup instructions

## Best Practices

### Notification Management
- ✅ Exclude post creator from notifications
- ✅ Respect user notification preferences
- ✅ Filter by community preference if needed
- ✅ Include meaningful data in notifications

### Performance
- ✅ Batch process notifications on server-side
- ✅ Use Cloud Functions for async operations
- ✅ Handle failures gracefully
- ✅ Limit notification frequency to avoid spam

### Security
- ✅ Use environment variables for sensitive keys
- ✅ Validate payloads before processing
- ✅ Use Appwrite permissions for data access
- ✅ Secure API keys in production

## Future Enhancements

1. **User Preferences**: Add granular notification controls
   - Notify on community posts (yes/no)
   - Notify on comments (yes/no)
   - Notify on likes (yes/no)

2. **Smart Notifications**: Filter by user interests
   - Only notify about mood tags user follows
   - Time-based notifications (respect quiet hours)

3. **Notification Analytics**: Track engagement
   - Monitor notification delivery rates
   - Track tap-through rates
   - Improve notification copy based on metrics

4. **In-App Notification Center**: Store notification history
   - Show recent notifications in-app
   - Mark as read/unread
   - Archive notifications

5. **Comments & Likes**: Extend to other interactions
   - Notify when someone comments on your post
   - Notify when someone likes your post
   - Threaded notifications for conversations

## Troubleshooting

### Notifications Not Received

**Check 1**: Are device tokens being saved?
```dart
// Verify in Appwrite: Users collection → user document → deviceTokens field
// Should contain at least one FCM token
```

**Check 2**: Is FCM_SERVER_KEY configured?
- Go to Appwrite Console → Functions → sendCommunityNotifications → Settings
- Verify FCM_SERVER_KEY environment variable is set

**Check 3**: Is the Cloud Function running?
- Trigger a test post
- Check Cloud Function logs in Appwrite Console
- Look for errors in execution history

**Check 4**: Are permissions correct?
- Verify user document has `notificationsEnabled: true`
- Check that `deviceTokens` array is not empty

### Post Creator Receives Own Notification

This should not happen due to the `Query.notEqual('$id', authorId)` filter in the Cloud Function. If it occurs:
- Verify `authorId` is being passed correctly
- Check Cloud Function logs for the query
- Ensure Appwrite user IDs are unique

## Support & References

- [Appwrite Documentation](https://appwrite.io/docs)
- [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)
- [Flutter Firebase Messaging](https://pub.dev/packages/firebase_messaging)
- [Appwrite Cloud Functions](https://appwrite.io/docs/products/functions)
