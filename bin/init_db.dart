// One-off setup script: creates every table in your Turso database if
// it doesn't exist yet. Run this once after you've set
// TURSO_DATABASE_URL and TURSO_AUTH_TOKEN (see README / .env.example),
// and again any time you add a new column via a tryAlter() in lib/db.dart.
//
//   dart run bin/init_db.dart
import 'package:robox_api/db.dart';

Future<void> main() async {
  print('Connecting to Turso and creating tables...');
  await initDb();
  print('Done. Your Turso database is ready.');
}
