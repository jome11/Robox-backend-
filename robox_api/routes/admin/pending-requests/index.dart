import 'package:dart_frog/dart_frog.dart';
import 'package:robox_api/db.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: 405, body: 'Method not allowed');
  }

  final db = getDb();
  final rows = await db.query(
    '''
    SELECT id, name, email, requested_at
    FROM pending_requests
    WHERE status = 'pending'
    ''',
  );

  final requests = rows
      .map(
        (row) => {
          'id': row['id'],
          'name': row['name'],
          'email': row['email'],
          'requestedDate': row['requested_at'],
        },
      )
      .toList();

  return Response.json(body: requests);
}
