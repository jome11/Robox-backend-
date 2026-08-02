import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:bcrypt/bcrypt.dart';
import '../../lib/db.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.patch) {
    return Response(statusCode: 405, body: 'Method not allowed');
  }

  final payload = context.read<Map<String, dynamic>>();
  final userId = payload['id'] as String;

  final body = jsonDecode(await context.request.body()) as Map<String, dynamic>;
  final newPassword = body['newPassword'] as String? ?? '';

  if (newPassword.length < 6) {
    return Response.json(statusCode: 400, body: {'error': 'PASSWORD_TOO_SHORT'});
  }

  final hash = BCrypt.hashpw(newPassword, BCrypt.gensalt());
  final db = getDb();
  db.execute(
    'UPDATE users SET password_hash = ?, must_change_password = 0 WHERE id = ?',
    [hash, userId],
  );

  return Response.json(statusCode: 200, body: {'message': 'Password updated'});
}