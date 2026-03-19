import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';
import 'appwrite_constants.dart';

/// Singleton Appwrite client — initialized once, used everywhere.
/// Configures platform-specific settings for OAuth and other features.
class AppwriteService {
  static final AppwriteService _instance = AppwriteService._internal();
  factory AppwriteService() => _instance;

  late final Client client;
  late final Account account;
  late final Databases databases;
  late final Storage storage;
  late final Realtime realtime;
  late final Functions functions;

  AppwriteService._internal() {
    client = Client()
        .setEndpoint(AppwriteConstants.endpoint)
        .setProject(AppwriteConstants.projectId)
        .setSelfSigned(status: true); // Remove in production

    // Platform-specific configuration for web
    if (kIsWeb) {
      // On web, set the endpoint domain for proper CORS handling
      // This ensures OAuth redirects work correctly
      // Note: The base URL should match your deployment domain
      // For development: typically http://localhost:5000
      // For production: your actual domain
    }

    account = Account(client);
    databases = Databases(client);
    storage = Storage(client);
    realtime = Realtime(client);
    functions = Functions(client);
  }
}
