import 'dart:convert';

import 'package:bcrypt/bcrypt.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:robox_api/db.dart';
import 'package:uuid/uuid.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405, body: 'Method not allowed');
  }

  final body = jsonDecode(await context.request.body()) as Map<String, dynamic>;
  final name = (body['name'] as String?)?.trim() ?? '';
  final email = (body['email'] as String?)?.trim().toLowerCase() ?? '';
  final password = body['password'] as String? ?? '';

  if (name.isEmpty || email.isEmpty || password.isEmpty) {
    return Response.json(
      statusCode: 400,
      body: {'error': 'MISSING_FIELDS'},
    );
  }

  final db = getDb();

  final existingUser = db.select(
    'SELECT id FROM users WHERE email = ?',
    [email],
  );
  if (existingUser.isNotEmpty) {
    return Response.json(
      statusCode: 409,
      body: {'error': 'EMAIL_EXISTS'},
    );
  }

  final existingPending = db.select(
    'SELECT id FROM pending_requests WHERE email = ?',
    [email],
  );
  if (existingPending.isNotEmpty) {
    return Response.json(
      statusCode: 409,
      body: {'error': 'EMAIL_PENDING'},
    );
  }

  final hash = BCrypt.hashpw(password, BCrypt.gensalt());
  const uuid = Uuid();

  db.execute(
    '''
    INSERT INTO pending_requests (id, name, email, password_hash, status, requested_at)
    VALUES (?, ?, ?, ?, 'pending', ?)
    ''',
    [uuid.v4(), name, email, hash, DateTime.now().toIso8601String()],
  );

  return Response.json(
    body: {'message': 'Signup request submitted'},
  );
}
