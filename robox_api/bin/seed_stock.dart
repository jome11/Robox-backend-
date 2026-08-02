import 'package:uuid/uuid.dart';
import '../lib/db.dart';

Future<void> main() async {
  await initDb();
  final db = getDb();
  const uuid = Uuid();

  final items = [
    {'name': 'ENDER 3 V3 KE', 'qty': 3, 'price': 160000.0},
    {'name': 'ENDER 3 V3 PLUS', 'qty': 5, 'price': 230000.0},
    {'name': 'ENDER-5 MAX', 'qty': 20, 'price': 350000.0},
    {'name': 'K2 PLUS', 'qty': 3, 'price': 460000.0},
    {'name': 'PLA FILAMENT', 'qty': 1200, 'price': 7200.0},
    {'name': 'ABS FILAMENT', 'qty': 120, 'price': 8500.0},
    {'name': 'PETG FILAMENT', 'qty': 120, 'price': 8500.0},
    {'name': 'TPU FILAMENT', 'qty': 60, 'price': 9800.0},
  ];

  for (final item in items) {
    final existing = await db.query('SELECT id FROM stock WHERE item_name = ?', [item['name']]);
    if (existing.isNotEmpty) {
      print('Skipping ${item['name']} — already exists');
      continue;
    }

    await db.execute(
      '''
      INSERT INTO stock (id, item_name, quantity, price, updated_at)
      VALUES (?, ?, ?, ?, ?)
      ''',
      [uuid.v4(), item['name'], item['qty'], item['price'], DateTime.now().toIso8601String()],
    );
    print('Seeded ${item['name']}');
  }
  print('Done.');
}
