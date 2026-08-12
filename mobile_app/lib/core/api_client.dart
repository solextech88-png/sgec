import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'constants.dart';

/// Thin wrapper around http.Client that:
///  - injects the Bearer token from secure storage on every request
///  - centralizes base URL + JSON encoding/decoding
///  - throws ApiException with the server's error message on non-2xx
///
/// Every feature's data layer should go through this instead of calling
/// http directly, so auth/error handling stays consistent app-wide.
class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);
  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  final _storage = const FlutterSecureStorage();
  final String baseUrl;

  ApiClient({this.baseUrl = AppConstants.apiBaseUrl});

  Future<Map<String, String>> _headers({bool json = true}) async {
    final token = await _storage.read(key: AppConstants.secureStorageTokenKey);
    return {
      if (json) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final res = await http.get(uri, headers: await _headers());
    return _handle(res);
  }

  Future<dynamic> post(String path, {Object? body}) async {
    final uri = Uri.parse('$baseUrl$path');
    final res = await http.post(uri, headers: await _headers(), body: jsonEncode(body));
    return _handle(res);
  }

  Future<dynamic> put(String path, {Object? body}) async {
    final uri = Uri.parse('$baseUrl$path');
    final res = await http.put(uri, headers: await _headers(), body: jsonEncode(body));
    return _handle(res);
  }

  Future<dynamic> delete(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final res = await http.delete(uri, headers: await _headers());
    return _handle(res);
  }

  /// Multipart upload for documents / signature images.
  Future<dynamic> uploadFile(
    String path, {
    required String fieldName,
    required String filePath,
    Map<String, String>? fields,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final request = http.MultipartRequest('POST', uri);
    final headers = await _headers(json: false);
    request.headers.addAll(headers);
    if (fields != null) request.fields.addAll(fields);
    request.files.add(await http.MultipartFile.fromPath(fieldName, filePath));

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    return _handle(res);
  }

  dynamic _handle(http.Response res) {
    final isJson = res.headers['content-type']?.contains('application/json') ?? false;
    final decoded = isJson && res.body.isNotEmpty ? jsonDecode(res.body) : res.body;

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return decoded;
    }
    final message = (decoded is Map && decoded['error'] != null)
        ? decoded['error'].toString()
        : 'Request failed (${res.statusCode})';
    throw ApiException(res.statusCode, message);
  }

  Future<void> saveSession(String token, String role) async {
    await _storage.write(key: AppConstants.secureStorageTokenKey, value: token);
    await _storage.write(key: AppConstants.secureStorageRoleKey, value: role);
  }

  Future<String?> getRole() => _storage.read(key: AppConstants.secureStorageRoleKey);
  Future<String?> getToken() => _storage.read(key: AppConstants.secureStorageTokenKey);

  Future<void> clearSession() async {
    await _storage.delete(key: AppConstants.secureStorageTokenKey);
    await _storage.delete(key: AppConstants.secureStorageRoleKey);
  }
}
