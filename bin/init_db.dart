import 'package:robox_api/db.dart';

Future<void> main() async {
  print('Connecting to Turso and creating tables...');
  await initDb();
  print('Done. Your Turso database is ready.');
}
