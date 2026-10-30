import 'package:dio/dio.dart' as dio;
import 'package:ecopin_app/core/services/api_service.dart';
import 'support_ticket.dart';

class SupportTicketApi {
  SupportTicketApi({dio.Dio? client}) : _dio = client ?? ApiClient().dioClient;
  final dio.Dio _dio;

  Future<SupportTicketPage> list({Map<String, String>? cursor}) async {
    final data = await _send(
      () => _dio.get('/api/support/tickets', queryParameters: {'limit': 20, ...?cursor}),
      'Your tickets could not load. Check your connection and try again.',
    );
    return SupportTicketPage.fromJson(data);
  }

  Future<SupportTicket> get(String reference) async {
    final data = await _send(
      () => _dio.get('/api/support/tickets/${Uri.encodeComponent(reference)}'),
      'This ticket could not load. Check your connection and try again.',
    );
    return SupportTicket.fromJson(data);
  }

  Future<SupportTicket> create({
    required String category,
    required String description,
    String? reportId,
  }) async {
    final data = await _send(
      () => _dio.post('/api/support/tickets', data: {
        'category': category,
        'description': description,
        'report_id': ?reportId,
      }),
      'Your ticket was not sent. Your text is still here; try again.',
    );
    return SupportTicket.fromJson(data);
  }

  Future<Map<String, dynamic>> _send(
    Future<dio.Response<dynamic>> Function() request,
    String fallback,
  ) async {
    try {
      final response = await request();
      return Map<String, dynamic>.from(response.data as Map);
    } on dio.DioException catch (error) {
      final body = error.response?.data;
      final message = body is Map ? body['error'] as String? : null;
      throw SupportTicketException(message ?? fallback);
    } catch (_) {
      throw SupportTicketException(fallback);
    }
  }
}
