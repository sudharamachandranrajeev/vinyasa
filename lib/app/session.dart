import 'package:brahma_core/brahma_core.dart';

import '../db/database.dart';
import '../domain/book.dart';

/// Vinyasa in Brahma's terms: the app's id, name and Android package.
const vinyasaIdentity = AppIdentity(
  id: 'vinyasa',
  name: 'Vinyasa',
  androidPackage: 'dev.brahma.vinyasa',
  releases: 'sudharamachandranrajeev/vinyasa',
);

/// Everything a running app needs: keys, the encrypted database and the
/// book on top of it. Opened once at start-up.
class AppSession extends CoreSession {
  AppSession(super.keys, super.store, this.book, {super.deviceName});

  final SpaceBook book;

  @override
  AppDatabase get db => store.db as AppDatabase;

  static Future<AppSession> open(KeyVault keys) => CoreSession.open(
    vinyasaIdentity,
    keys,
    openDatabase: AppDatabase.open,
    build: (store, deviceName) => AppSession(keys, store, SpaceBook(store), deviceName: deviceName),
  );
}
