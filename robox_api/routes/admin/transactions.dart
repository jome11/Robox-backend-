import 'package:dart_frog/dart_frog.dart';
import 'package:robox_api/db.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: 405, body: 'Method not allowed');
  }

  final db = getDb();
  final rows = db.select('SELECT * FROM transactions ORDER BY created_at DESC');

  final transactions = rows
      .map(
        (row) => {
          'id': row['id'],
          'title': row['title'],
          'amount': row['amount'],
          'type': row['type'],
          'category': row['category'],
          'subCategory': row['sub_category'],
          'customCategory': row['custom_category'],
          'description': row['description'],
          'addedBy': row['added_by_name'],
          'date': row['created_at'],
        },
      )
      .toList();

  return Response.json(body: {'transactions': transactions});
}
