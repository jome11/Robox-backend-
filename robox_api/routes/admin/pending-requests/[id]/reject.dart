import 'package:dart_frog/dart_frog.dart';
import '../../../../lib/db.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405, body: 'Method not allowed');
  }

  final db = getDb();

  db.execute(
    "UPDATE pending_requests SET status = 'rejected' WHERE id = ?",
    [id],
  );

  return Response.json(statusCode: 200, body: {'message': 'Rejected'});
}