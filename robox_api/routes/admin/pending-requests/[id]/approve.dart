import 'package:dart_frog/dart_frog.dart';
import 'package:robox_api/db.dart';
import 'package:uuid/uuid.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405, body: 'Method not allowed');
  }

  final db = getDb();

  final result = db.select(
    'SELECT name, email, password_hash FROM pending_requests WHERE id = ?',
    [id],
  );

  if (result.isEmpty) {
    return Response.json(statusCode: 404, body: {'error': 'NOT_FOUND'});
  }

  final row = result.first;
  const uuid = Uuid();

  db
    ..execute(
      '''
      INSERT INTO users (id, name, email, password_hash, role, created_at)
      VALUES (?, ?, ?, ?, 'worker', ?)
      ''',
      [
        uuid.v4(),
        row['name'],
        row['email'],
        row['password_hash'],
        DateTime.now().toIso8601String(),
      ],
    )
    ..execute(
      "UPDATE pending_requests SET status = 'approved' WHERE id = ?",
      [id],
    );

  return Response.json(body: {'message': 'Approved'});
}
