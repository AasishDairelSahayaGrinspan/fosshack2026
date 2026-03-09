import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import '../constants/appwrite_constants.dart';

final appwriteClientProvider = Provider<Client>((ref) {
  return Client()
      .setEndpoint(AppwriteConstants.endpoint)
      .setProject(AppwriteConstants.projectId)
      .setSelfSigned(status: true);
});

final appwriteAccountProvider = Provider<Account>((ref) {
  return Account(ref.read(appwriteClientProvider));
});

final appwriteDatabasesProvider = Provider<Databases>((ref) {
  return Databases(ref.read(appwriteClientProvider));
});

final appwriteFunctionsProvider = Provider<Functions>((ref) {
  return Functions(ref.read(appwriteClientProvider));
});
