import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import '../../../lib/db.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.patch) {
    return Response(statusCode: 405, body: 'Method not allowed');
  }

  final payload = context.read<Map<String, dynamic>>();
  final userId = payload['id'] as String;
  final role = payload['role'] as String;

  final db = getDb();
  final rows = await db.query('SELECT added_by_id FROM transactions WHERE id = ?', [id]);
  if (rows.isEmpty) {
    return Response.json(statusCode: 404, body: {'error': 'NOT_FOUND'});
  }
  final ownerId = rows.first['added_by_id'] as String;
  if (ownerId != userId && role != 'admin') {
    return Response.json(statusCode: 403, body: {'error': 'FORBIDDEN'});
  }

  final body = jsonDecode(await context.request.body()) as Map<String, dynamic>;

  final title = body['title'] as String?;
  final amount = (body['amount'] as num?)?.toDouble();
  final description = body['description'] as String?;

  if (title == null && amount == null && description == null) {
    return Response.json(statusCode: 400, body: {'error': 'NOTHING_TO_UPDATE'});
  }

  final updates = <String>[];
  final args = <dynamic>[];

  if (title != null) {
    updates.add('title = ?');
    args.add(title);
  }
  if (amount != null) {
    updates.add('amount = ?');
    args.add(amount);
  }
  if (description != null) {
    updates.add('description = ?');
    args.add(description);
  }
  updates.add('edited = 1');
  args.add(id);

  await db.execute('UPDATE transactions SET ${updates.join(', ')} WHERE id = ?', args);

  return Response.json(statusCode: 200, body: {'message': 'Updated'});
}
