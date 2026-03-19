/**
 * Appwrite Cloud Function: Send Community Post Notifications
 * 
 * Triggered when a user posts in the community.
 * Queries all users in the system (except the post creator),
 * and sends push notifications to each user.
 * 
 * Environment variables required:
 * - APPWRITE_API_KEY: Appwrite API key with proper permissions
 * - APPWRITE_DATABASE_ID: The database ID (e.g., 'unravel_db')
 * - APPWRITE_USERS_COLLECTION_ID: Users collection ID
 * - FCM_SERVER_KEY: Firebase Cloud Messaging server key (if using FCM)
 */

const { Client, Databases, Query } = require('node-appwrite');

module.exports = async function (req, res) {
  // Parse the request body
  let payload;
  try {
    payload = JSON.parse(req.bodyRaw);
  } catch (e) {
    return res.json({
      success: false,
      message: 'Invalid request body',
      error: e.message,
    }, 400);
  }

  const { postId, authorId, authorName, postTitle } = payload;

  if (!postId || !authorId) {
    return res.json({
      success: false,
      message: 'Missing required fields: postId, authorId',
    }, 400);
  }

  try {
    // Initialize Appwrite client with admin permissions
    const client = new Client()
      .setEndpoint('https://cloud.appwrite.io/v1')
      .setProject(req.env.APPWRITE_PROJECT_ID || 'unravel-app')
      .setKey(req.env.APPWRITE_API_KEY);

    const databases = new Databases(client);
    const databaseId = req.env.APPWRITE_DATABASE_ID || 'unravel_db';
    const usersCollectionId = req.env.APPWRITE_USERS_COLLECTION_ID || 'users';

    // Query all users except the post creator
    const usersList = await databases.listDocuments(
      databaseId,
      usersCollectionId,
      [
        Query.notEqual('$id', authorId),
        Query.limit(100), // Adjust limit as needed
      ]
    );

    const notifiedUsers = [];
    const failedNotifications = [];

    // Process each user
    for (const user of usersList.documents) {
      try {
        // Check if user has push notifications enabled and device tokens
        const deviceTokens = user.deviceTokens || [];
        const notificationsEnabled = user.notificationsEnabled !== false;

        if (!notificationsEnabled || deviceTokens.length === 0) {
          continue;
        }

        // Send notification to each device token
        for (const token of deviceTokens) {
          try {
            await sendPushNotification({
              deviceToken: token,
              title: `${authorName} posted in Community`,
              body: postTitle.substring(0, 100),
              data: {
                postId,
                type: 'community_post',
                authorId,
                authorName,
              },
            });

            notifiedUsers.push({
              userId: user.$id,
              deviceToken: token,
            });
          } catch (tokenError) {
            failedNotifications.push({
              userId: user.$id,
              deviceToken: token,
              error: tokenError.message,
            });
          }
        }
      } catch (userError) {
        console.error(`Error processing user ${user.$id}:`, userError);
        failedNotifications.push({
          userId: user.$id,
          error: userError.message,
        });
      }
    }

    // Log notification results
    console.log(`Community notification sent for post ${postId}`);
    console.log(`Successfully notified: ${notifiedUsers.length} devices`);
    console.log(`Failed notifications: ${failedNotifications.length}`);

    return res.json({
      success: true,
      postId,
      message: `Notifications sent to ${notifiedUsers.length} users`,
      notifiedCount: notifiedUsers.length,
      failedCount: failedNotifications.length,
    });
  } catch (error) {
    console.error('Cloud function error:', error);
    return res.json({
      success: false,
      message: 'Failed to send community notifications',
      error: error.message,
    }, 500);
  }
};

/**
 * Send push notification via Firebase Cloud Messaging (FCM)
 * Requires FCM_SERVER_KEY environment variable
 */
async function sendPushNotification({ deviceToken, title, body, data }) {
  const fcmServerKey = process.env.FCM_SERVER_KEY;

  if (!fcmServerKey) {
    // If FCM is not configured, just log and return
    console.log('FCM not configured, skipping push notification');
    return;
  }

  try {
    const response = await fetch('https://fcm.googleapis.com/fcm/send', {
      method: 'POST',
      headers: {
        'Authorization': `key=${fcmServerKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        to: deviceToken,
        notification: {
          title,
          body,
          sound: 'default',
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
        data: data || {},
        priority: 'high',
      }),
    });

    const result = await response.json();

    if (!response.ok || result.failure > 0) {
      throw new Error(`FCM error: ${result.results?.[0]?.error || 'Unknown error'}`);
    }

    return result;
  } catch (error) {
    console.error('FCM push notification error:', error);
    throw error;
  }
}
