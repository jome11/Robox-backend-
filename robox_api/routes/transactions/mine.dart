import 'package:dart_frog/dart_frog.dart';
import '../../lib/db.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: 405, body: 'Method not allowed');
  }

  final payload = context.read<Map<String, dynamic>>();
  final userId = payload['id'] as String;

  final db = getDb();
  final rows = db.select(
    'SELECT * FROM transactions WHERE added_by_id = ? ORDER BY created_at DESC',
    [userId],
  );

  final transactions = rows.map(_rowToJson).toList();
  return Response.json(statusCode: 200, body: {'transactions': transactions});
}

Map<String, dynamic> _rowToJson(dynamic row) => {
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
    };