import 'package:http/http.dart' as http;

class ApiError extends Error {}

class ApiClient extends http.IOClient {
  static const String scheme = 'https';
  static const String host = 'example.com';
  static const int port = 443;
  static const String scope = '/v1';

  String authToken;

  Map<String, String> get defaultHeaders => <String, String>{
        'Content-Type': 'application/json',
      };

  String getUrl({String path, Map<String, dynamic> queryParams}) {
    final Uri uri = Uri(
      scheme: scheme,
      host: host,
      port: port,
      queryParameters: queryParams,
      path: '${scope ?? ''}$path',
    );

    return uri.toString();
  }
}
