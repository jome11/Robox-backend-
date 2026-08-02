import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:uuid/uuid.dart';
import '../../../lib/db.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405, body: 'Method not allowed');
  }

  final body = jsonDecode(await context.request.body()) as Map<String, dynamic>;
  final items = body['items'] as List<dynamic>?;

  if (items == null || items.isEmpty) {
    return Response.json(statusCode: 400, body: {'error': 'MISSING_ITEMS'});
  }

  final db = getDb();
  const uuid = Uuid();
  final restocked = <String>[];

  for (final item in items) {
    final map = item as Map<String, dynamic>;
    final itemName = (map['itemName'] as String?)?.trim() ?? '';
    final quantity = (map['quantity'] as num?)?.toInt() ?? 0;
    final price = (map['price'] as num?)?.toDouble();

    if (itemName.isEmpty || quantity <= 0) continue;

    final existing = await db.query('SELECT id, quantity FROM stock WHERE item_name = ?', [itemName]);

    if (existing.isNotEmpty) {
      final currentQty = existing.first['quantity'] as int;
      await db.execute(
        'UPDATE stock SET quantity = ?, updated_at = ?${price != null ? ', price = ?' : ''} WHERE item_name = ?',
        price != null
            ? [currentQty + quantity, DateTime.now().toIso8601String(), price, itemName]
            : [currentQty + quantity, DateTime.now().toIso8601String(), itemName],
      );
    } else {
      await db.execute(
        'INSERT INTO stock (id, item_name, quantity, price, updated_at) VALUES (?, ?, ?, ?, ?)',
        [uuid.v4(), itemName, quantity, price ?? 0.0, DateTime.now().toIso8601String()],
      );
    }
    restocked.add(itemName);
  }

  return Response.json(statusCode: 200, body: {'message': 'Restocked', 'items': restocked});
}
