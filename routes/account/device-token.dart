import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import '../../lib/db.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405, body: 'Method not allowed');
  }

  final payload = context.read<Map<String, dynamic>>();
  final userId = payload['id'] as String;

  final body = jsonDecode(await context.request.body()) as Map<String, dynamic>;
  final token = (body['token'] as String?)?.trim() ?? '';

  if (token.isEmpty) {
    return Response.json(statusCode: 400, body: {'error': 'MISSING_TOKEN'});
  }

  final db = getDb();
  await db.execute('UPDATE users SET fcm_token = ? WHERE id = ?', [token, userId]);

  return Response.json(statusCode: 200, body: {'message': 'Token saved'});
}