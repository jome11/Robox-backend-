import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import '../lib/db.dart';

const jwtSecret = 'temporary-dev-secret-change-this-later';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405, body: 'Method not allowed');
  }

  final body = jsonDecode(await context.request.body()) as Map<String, dynamic>;
  final email = (body['email'] as String?)?.trim().toLowerCase() ?? '';
  final password = body['password'] as String? ?? '';

  if (email.isEmpty || password.isEmpty) {
    return Response.json(
      statusCode: 400,
      body: {'error': 'MISSING_FIELDS'},
    );
  }

  final db = getDb();

  // Check pending first — matches ACCOUNT_PENDING in your Flutter contract
  final pending = db.select(
    'SELECT id FROM pending_requests WHERE email = ? AND status = ?',
    [email, 'pending'],
  );
  if (pending.isNotEmpty) {
    return Response.json(
      statusCode: 403,
      body: {'error': 'ACCOUNT_PENDING'},
    );
  }

  // Check real users
  final result = db.select(
    'SELECT id, name, email, password_hash, role FROM users WHERE email = ?',
    [email],
  );

  if (result.isEmpty) {
    return Response.json(
      statusCode: 401,
      body: {'error': 'INVALID_CREDENTIALS'},
    );
  }

  final row = result.first;
  final storedHash = row['password_hash'] as String;

  final passwordMatches = BCrypt.checkpw(password, storedHash);
  if (!passwordMatches) {
    return Response.json(
      statusCode: 401,
      body: {'error': 'INVALID_CREDENTIALS'},
    );
  }

  final jwt = JWT({
    'id': row['id'],
    'role': row['role'],
  });
  final token = jwt.sign(SecretKey(jwtSecret), expiresIn: const Duration(hours: 2));

  return Response.json(
    statusCode: 200,
    body: {
      'token': token,
      'user': {
        'id': row['id'],
        'name': row['name'],
        'email': row['email'],
        'role': row['role'],
      },
    },
  );
}