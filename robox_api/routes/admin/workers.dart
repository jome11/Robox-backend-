import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import '../../lib/db.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: 405, body: 'Method not allowed');
  }

  final db = getDb();
  final result = db.select(
    "SELECT id, name, email, role, created_at FROM users WHERE role = ?",
    ['worker'],
  );

  final workers = result.map((row) => {
    'id': row['id'],
    'name': row['name'],
    'email': row['email'],
    'role': row['role'],
    'created_at': row['created_at'],
  }).toList();

  return Response.json(
    statusCode: 200,
    body: {'workers': workers},
  );
}