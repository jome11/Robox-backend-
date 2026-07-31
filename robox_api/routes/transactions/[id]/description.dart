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
  final rows = db.select('SELECT added_by_id FROM transactions WHERE id = ?', [id]);
  if (rows.isEmpty) {
    return Response.json(statusCode: 404, body: {'error': 'NOT_FOUND'});
  }
  final ownerId = rows.first['added_by_id'] as String;
  if (ownerId != userId && role != 'admin') {
    return Response.json(statusCode: 403, body: {'error': 'FORBIDDEN'});
  }

  final body = jsonDecode(await context.request.body()) as Map<String, dynamic>;
  final description = body['description'] as String? ?? '';

  db.execute('UPDATE transactions SET description = ? WHERE id = ?', [description, id]);

  return Response.json(statusCode: 200, body: {'message': 'Updated'});
}