import 'package:appwrite/appwrite.dart';
import 'appwrite_constants.dart';

/// Singleton Appwrite client — initialized once, used everywhere.
class AppwriteService {
  static final AppwriteService _instance = AppwriteService._internal();
  factory AppwriteService() => _instance;

  late final Client client;
  late final Account account;
  late final TablesDB tablesDb;
  late final Storage storage;
  late final Realtime realtime;

  AppwriteService._internal() {
    client = Client()
        .setEndpoint(AppwriteConstants.endpoint)
        .setProject(AppwriteConstants.projectId)
        .setSelfSigned(status: true); // Remove in production

    account = Account(client);
    tablesDb = TablesDB(client);
    storage = Storage(client);
    realtime = Realtime(client);
  }
}
