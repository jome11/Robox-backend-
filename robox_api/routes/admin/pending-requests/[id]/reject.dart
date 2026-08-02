import 'package:dart_frog/dart_frog.dart';
import 'package:robox_api/db.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405, body: 'Method not allowed');
  }

  final db = getDb();

  // ignore: avoid_single_cascade_in_expression_statements, cascade_invocations
  db.execute(
    "UPDATE pending_requests SET status = 'rejected' WHERE id = ?",
    [id],
  );

  return Response.json(body: {'message': 'Rejected'});
}
