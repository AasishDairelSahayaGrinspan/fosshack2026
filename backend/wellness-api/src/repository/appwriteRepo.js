import { Client, Databases, ID, Query } from 'node-appwrite';

function requiredEnv(name, fallback) {
  const value = process.env[name] || fallback;
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

export function createRepository() {
  const endpoint = requiredEnv('APPWRITE_ENDPOINT', 'https://cloud.appwrite.io/v1');
  const projectId = requiredEnv('APPWRITE_PROJECT_ID', 'unravel-app');
  const databaseId = requiredEnv('APPWRITE_DATABASE_ID', 'unravel_db');
  const collectionId = requiredEnv('APPWRITE_WELLNESS_COLLECTION_ID', 'wellness_logs');
  const apiKey = requiredEnv('APPWRITE_API_KEY');

  const client = new Client()
    .setEndpoint(endpoint)
    .setProject(projectId)
    .setKey(apiKey);

  const databases = new Databases(client);

  return {
    async upsertLog(payload) {
      const { id, ...data } = payload;
      await databases.createDocument(
        databaseId,
        collectionId,
        id || ID.unique(),
        data
      );
    },

    async getRecentLogs(userId, limit = 30) {
      const result = await databases.listDocuments(databaseId, collectionId, [
        Query.equal('user_id', userId),
        Query.orderDesc('log_date'),
        Query.limit(limit)
      ]);

      return result.documents.map((doc) => ({ ...doc }));
    }
  };
}
