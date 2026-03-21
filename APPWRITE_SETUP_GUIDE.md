# Appwrite Backend Setup Guide

## ⚠️ IMPORTANT SECURITY NOTE
**CHANGE YOUR PASSWORD IMMEDIATELY!** You shared it publicly: `feXzep-fykmu0-nutvef`

Go to: https://fra.cloud.appwrite.io/console → Account Settings → Change Password

---

## 🎯 Quick Setup Checklist

Your app is already coded to sync with Appwrite. You just need to create the database structure.

### Step 1: Login to Appwrite Console
1. Go to: https://fra.cloud.appwrite.io/console
2. Login with: `aasishdairel@gmail.com`
3. Select project: `unravel-app`

### Step 2: Create Database
1. Click **Databases** in left sidebar
2. Click **Create Database**
3. Database ID: `unravel_db`
4. Database Name: `Unravel Database`
5. Click **Create**

### Step 3: Create Collections

For each collection below, click **Create Collection** and follow the structure:

---

#### 📝 **Collection 1: users**
- **Collection ID**: `users`
- **Collection Name**: Users
- **Permissions**: 
  - Create: Users
  - Read: Users
  - Update: Users

**Attributes:**
```
userId          | String  | Required | Size: 255
name            | String  | Required | Size: 255
ageGroup        | String  | Optional | Size: 50
concerns        | String[]| Optional
sleepSchedule   | String  | Optional | Size: 100
moodBaseline    | Float   | Optional | Default: 0.5
avatarUrl       | String  | Optional | Size: 500
hairStyle       | Integer | Optional | Default: 0
skinTone        | Integer | Optional | Default: 0
outfitColor     | Integer | Optional | Default: 0
musicLanguages  | String[]| Optional
createdAt       | String  | Required | Size: 100
communityPreference | String | Optional | Size: 10
```

---

#### 😊 **Collection 2: mood_entries**
- **Collection ID**: `mood_entries`
- **Collection Name**: Mood Entries
- **Permissions**: Users can create/read/update their own

**Attributes:**
```
userId      | String | Required | Size: 255
mood        | Float  | Required
emoji       | String | Required | Size: 10
note        | String | Optional | Size: 1000
timestamp   | String | Required | Size: 100
```

**Indexes:**
```
Index 1: userId (Ascending)
Index 2: timestamp (Descending)
```

---

#### 📔 **Collection 3: journal_entries**
- **Collection ID**: `journal_entries`
- **Collection Name**: Journal Entries
- **Permissions**: Users can create/read/update their own

**Attributes:**
```
userId      | String | Required | Size: 255
title       | String | Required | Size: 500
content     | String | Required | Size: 10000
timestamp   | String | Required | Size: 100
mediaFileId | String | Optional | Size: 255
tags        | String[]| Optional
mood        | Float  | Optional
```

**Indexes:**
```
Index 1: userId (Ascending)
Index 2: timestamp (Descending)
```

---

#### 🔥 **Collection 4: streaks**
- **Collection ID**: `streaks`
- **Collection Name**: Streaks
- **Permissions**: Users can create/read/update their own

**Attributes:**
```
userId          | String  | Required | Size: 255
currentStreak   | Integer | Required | Default: 0
longestStreak   | Integer | Required | Default: 0
lastCheckInDate | String  | Required | Size: 100
```

**Indexes:**
```
Index 1: userId (Ascending)
```

---

#### 📊 **Collection 5: recovery_scores**
- **Collection ID**: `recovery_scores`
- **Collection Name**: Recovery Scores
- **Permissions**: Users can create/read/update their own

**Attributes:**
```
userId      | String | Required | Size: 255
date        | String | Required | Size: 100
score       | Float  | Required
moodAvg     | Float  | Optional
sleepHours  | Float  | Optional
stressLevel | Float  | Optional
```

**Indexes:**
```
Index 1: userId (Ascending)
Index 2: date (Descending)
```

---

#### 🌐 **Collection 6: posts**
- **Collection ID**: `posts`
- **Collection Name**: Community Posts
- **Permissions**: 
  - Create: Users
  - Read: Any (public)
  - Update: Users (own posts)
  - Delete: Users (own posts)

**Attributes:**
```
userId      | String  | Required | Size: 255
username    | String  | Required | Size: 255
avatar      | String  | Optional | Size: 500
content     | String  | Required | Size: 5000
imagePath   | String  | Optional | Size: 500
imageFileId | String  | Optional | Size: 255
likes       | Integer | Required | Default: 0
timestamp   | String  | Required | Size: 100
comments    | String  | Optional | Size: 50000 (JSON array)
```

**Indexes:**
```
Index 1: userId (Ascending)
Index 2: timestamp (Descending)
Index 3: likes (Descending)
```

---

#### 💬 **Collection 7: comments**
- **Collection ID**: `comments`
- **Collection Name**: Comments
- **Permissions**: 
  - Create: Users
  - Read: Any (public)
  - Update: Users (own comments)

**Attributes:**
```
postId      | String | Required | Size: 255
userId      | String | Required | Size: 255
username    | String | Required | Size: 255
avatar      | String | Optional | Size: 500
content     | String | Required | Size: 2000
timestamp   | String | Required | Size: 100
```

**Indexes:**
```
Index 1: postId (Ascending)
Index 2: userId (Ascending)
Index 3: timestamp (Descending)
```

---

### Step 4: Create Storage Buckets

1. Click **Storage** in left sidebar
2. Click **Create Bucket** for each:

#### Bucket 1: profile_pics
- **Bucket ID**: `profile_pics`
- **Bucket Name**: Profile Pictures
- **File Size Limit**: 5 MB
- **Allowed Extensions**: jpg, jpeg, png, webp
- **Permissions**: Users can create/read/update their own

#### Bucket 2: journal_media
- **Bucket ID**: `journal_media`
- **Bucket Name**: Journal Media
- **File Size Limit**: 10 MB
- **Allowed Extensions**: jpg, jpeg, png, mp4, mp3
- **Permissions**: Users can create/read/update their own

#### Bucket 3: post_images
- **Bucket ID**: `post_images`
- **Bucket Name**: Post Images
- **File Size Limit**: 5 MB
- **Allowed Extensions**: jpg, jpeg, png, webp, gif
- **Permissions**: 
  - Create: Users
  - Read: Any (public)

#### Bucket 4: music_tracks
- **Bucket ID**: `music_tracks`
- **Bucket Name**: Music Tracks
- **File Size Limit**: 20 MB
- **Allowed Extensions**: mp3, wav, m4a
- **Permissions**: Read: Any (public)

---

### Step 5: Configure OAuth

1. Go to **Auth** → **Settings** in Appwrite Console
2. Enable **Google OAuth**
3. Add your Google OAuth credentials
4. Set Success URL: `appwrite-callback-unravel-app://`
5. Set Failure URL: `appwrite-callback-unravel-app://`

---

### Step 6: Enable Anonymous Sessions

1. Go to **Auth** → **Settings**
2. Scroll to **Sessions**
3. Enable **Anonymous Sessions**
4. Save

---

## ✅ Verification

After setup, your app will automatically:
- ✅ Sync mood entries to Appwrite
- ✅ Sync journal entries to Appwrite
- ✅ Sync community posts to Appwrite
- ✅ Sync user profiles to Appwrite
- ✅ Store media in Appwrite storage
- ✅ Use realtime updates for community

---

## 🔧 Already Implemented Features

Your app already has:
- ✅ Offline-first architecture (works without internet)
- ✅ Automatic sync when online
- ✅ Local cache fallback
- ✅ Realtime updates for community posts
- ✅ Secure permissions (users only see their own data)

---

## 📱 Test After Setup

1. Run: `flutter run`
2. Login with Google or Guest
3. Add a mood entry → Check Appwrite Console
4. Write a journal → Check Appwrite Console
5. Post in community → Check Appwrite Console

All data should appear in your Appwrite database!

---

## 🆘 Troubleshooting

**If data doesn't sync:**
1. Check internet connection
2. Verify database ID matches: `unravel_db`
3. Check collection IDs match exactly
4. Check permissions are set correctly
5. Look at Flutter debug console for errors

**Common Issues:**
- Wrong collection ID → Data won't save
- Missing attributes → App will crash
- Wrong permissions → Access denied errors
- Missing indexes → Slow queries

---

## 📚 Next Steps

After basic setup:
1. Add more users and test multi-user features
2. Set up automated backups
3. Configure rate limits
4. Add webhook for notifications
5. Set up functions for complex operations

---

## 🔐 Security Reminders

- [ ] Change your password NOW
- [ ] Enable 2FA on Appwrite account
- [ ] Review collection permissions
- [ ] Set up API key rotation
- [ ] Monitor usage for suspicious activity
