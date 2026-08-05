import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:robox_api/db.dart';

Future<Response> onRequest(RequestContext context) async {
  final payload = context.read<Map<String, dynamic>>();
  final userId = payload['id'] as String;
  final db = getDb();

  if (context.request.method == HttpMethod.get) {
    final rows = await db.query(
      'SELECT id, name, email, role, is_active, must_change_password FROM users WHERE id = ?',
      [userId],
    );
    if (rows.isEmpty || (rows.first['is_active'] as int) == 0) {
      return Response.json(statusCode: 401, body: {'error': 'INVALID_SESSION'});
    }
    final row = rows.first;
    return Response.json(statusCode: 200, body: {
      'id': row['id'],
      'name': row['name'],
      'email': row['email'],
      'role': row['role'],
      'mustChangePassword': (row['must_change_password'] as int) == 1,
    });
  }

  if (context.request.method != HttpMethod.patch) {
    return Response(statusCode: 405, body: 'Method not allowed');
  }

  final body = jsonDecode(await context.request.body()) as Map<String, dynamic>;
  final name = (body['name'] as String?)?.trim();
  final email = (body['email'] as String?)?.trim().toLowerCase();

  if ((name == null || name.isEmpty) && (email == null || email.isEmpty)) {
    return Response.json(statusCode: 400, body: {'error': 'NOTHING_TO_UPDATE'});
  }

  if (email != null && email.isNotEmpty) {
    final existing = await db.query(
      'SELECT id FROM users WHERE email = ? AND id != ?',
      [email, userId],
    );
    if (existing.isNotEmpty) {
      return Response.json(statusCode: 409, body: {'error': 'EMAIL_EXISTS'});
    }
  }

  final updates = <String>[];
  final args = <dynamic>[];
  if (name != null && name.isNotEmpty) {
    updates.add('name = ?');
    args.add(name);
  }
  if (email != null && email.isNotEmpty) {
    updates.add('email = ?');
    args.add(email);
  }
  args.add(userId);

  await db.execute('UPDATE users SET ${updates.join(', ')} WHERE id = ?', args);

  return Response.json(statusCode: 200, body: {'message': 'Profile updated'});
}