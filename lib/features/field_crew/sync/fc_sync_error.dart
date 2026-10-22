import 'package:dio/dio.dart';

bool fcCanResetTransportError(String message) {
  final match = RegExp(r'^HTTP (\d{3}):').firstMatch(message);
  final status = int.tryParse(match?.group(1) ?? '');
  return status != null &&
      (status >= 500 || const [401, 404, 408, 429].contains(status));
}

/// Keep useful API messages, not the transport stack or raw response body.
String fcSyncError(DioException error) {
  final status = error.response?.statusCode;
  final body = error.response?.data;
  final message = body is Map ? body['message'] ?? body['error'] : null;
  final detail = message is String && message.trim().isNotEmpty
      ? message.trim()
      : status == null
      ? 'Could not reach the server. Check your connection and try again.'
      : 'The server could not process this request.';
  final hint = status == 404
      ? ' Check that the backend is updated and the sync endpoint is available.'
      : '';
  return '${status == null ? '' : 'HTTP $status: '}$detail$hint';
}
