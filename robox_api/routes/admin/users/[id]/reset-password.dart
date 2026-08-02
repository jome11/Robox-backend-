import 'dart:math';
import 'package:dart_frog/dart_frog.dart';
import 'package:bcrypt/bcrypt.dart';
import '../../../../lib/db.dart';

String _generatePassword() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789';
  final rand = Random.secure();
  return List.generate(10, (_) => chars[rand.nextInt(chars.length)]).join();
}

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405, body: 'Method not allowed');
  }

  final db = getDb();

  final existing = db.select('SELECT id FROM users WHERE id = ?', [id]);
  if (existing.isEmpty) {
    return Response.json(statusCode: 404, body: {'error': 'NOT_FOUND'});
  }

  final newPassword = _generatePassword();
  final hash = BCrypt.hashpw(newPassword, BCrypt.gensalt());

  db.execute(
    'UPDATE users SET password_hash = ?, must_change_password = 1 WHERE id = ?',
    [hash, id],
  );

  return Response.json(
    statusCode: 200,
    body: {'message': 'Password reset', 'newPassword': newPassword},
  );
}