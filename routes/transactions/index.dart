import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:uuid/uuid.dart';
import '../../lib/db.dart';
import '../../lib/fcm_service.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405, body: 'Method not allowed');
  }

  final payload = context.read<Map<String, dynamic>>();
  final userId = payload['id'] as String;

  final db = getDb();
  final userRow = await db.query('SELECT name FROM users WHERE id = ?', [userId]);
  final userName = userRow.isNotEmpty ? userRow.first['name'] as String : 'Unknown User';

  final body = jsonDecode(await context.request.body()) as Map<String, dynamic>;
  final title = (body['title'] as String?)?.trim() ?? '';
  final amount = (body['amount'] as num?)?.toDouble();
  final type = body['type'] as String? ?? '';
  final category = body['category'] as String?;
  final subCategory = body['subCategory'] as String?;
  final customCategory = body['customCategory'] as String?;
  final description = body['description'] as String?;
  final quantity = (body['quantity'] as num?)?.toInt();

  if (title.isEmpty || amount == null || amount <= 0 || (type != 'income' && type != 'expense')) {
    return Response.json(statusCode: 400, body: {'error': 'MISSING_FIELDS'});
  }

  // If this is a sale of a stock item, check availability BEFORE logging anything.
  Map<String, dynamic>? stockRow;
  if (type == 'income' && subCategory != null && quantity != null && quantity > 0) {
    final rows = await db.query('SELECT id, quantity FROM stock WHERE item_name = ?', [subCategory]);
    if (rows.isNotEmpty) {
      stockRow = rows.first;
      final available = stockRow['quantity'] as int;
      if (quantity > available) {
        return Response.json(
          statusCode: 400,
          body: {'error': 'INSUFFICIENT_STOCK', 'available': available},
        );
      }
    }
  }

  const uuid = Uuid();
  final id = uuid.v4();
  final now = DateTime.now().toIso8601String();

  await db.execute(
    '''
    INSERT INTO transactions (id, title, amount, type, category, sub_category, custom_category, description, added_by_id, added_by_name, created_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''',
    [id, title, amount, type, category, subCategory, customCategory, description, userId, userName, now],
  );

  // Decrement stock if this sale matched a real stock item.
  if (stockRow != null) {
    final currentQty = stockRow['quantity'] as int;
    await db.execute(
      'UPDATE stock SET quantity = ?, updated_at = ? WHERE id = ?',
      [currentQty - quantity!, now, stockRow['id']],
    );
  }

  // Notify admins (excluding whoever just logged this) with the transaction detail.
  final adminTokens = await db.query(
    "SELECT fcm_token FROM users WHERE role = 'admin' AND fcm_token IS NOT NULL AND id != ?",
    [userId],
  );
  final tokens = adminTokens.map((r) => r['fcm_token'] as String).toList();

  await FcmService.sendToTokens(
    tokens,
    title: type == 'income' ? 'New Income Logged' : 'New Expense Logged',
    body: '$userName logged ETB ${amount.toStringAsFixed(2)} — $title',
    data: {'type': 'transaction', 'transactionId': id},
  );

  return Response.json(statusCode: 200, body: {'message': 'Transaction logged', 'id': id});
}