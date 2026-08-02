import 'package:dart_frog/dart_frog.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

const jwtSecret = 'temporary-dev-secret-change-this-later';

Handler middleware(Handler handler) {
  return (context) async {
    final authHeader = context.request.headers['authorization'];

    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return Response.json(statusCode: 401, body: {'error': 'NO_TOKEN'});
    }

    final token = authHeader.substring(7);

    try {
      final jwt = JWT.verify(token, SecretKey(jwtSecret));
      final payload = jwt.payload as Map<String, dynamic>;

      // Any valid, non-expired token gets through — attach the user id
      // for the route to use.
      return handler(context.provide(() => payload));
    } on JWTExpiredException {
      return Response.json(statusCode: 401, body: {'error': 'TOKEN_EXPIRED'});
    } catch (_) {
      return Response.json(statusCode: 401, body: {'error': 'INVALID_TOKEN'});
    }
  };
}
