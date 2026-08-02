import 'package:dart_frog/dart_frog.dart';
import '../../../../lib/db.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405, body: 'Method not allowed');
  }

  final db = getDb();

  final existing = await db.query('SELECT id FROM users WHERE id = ?', [id]);
  if (existing.isEmpty) {
    return Response.json(statusCode: 404, body: {'error': 'NOT_FOUND'});
  }

  await db.execute('UPDATE users SET is_active = 0 WHERE id = ?', [id]);

  return Response.json(statusCode: 200, body: {'message': 'Deactivated'});
}
