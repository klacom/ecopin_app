const ticketCategories = <String, String>{
  'status_inquiry': 'Status inquiry',
  'location_mismatch': 'Location correction',
  're_inspection': 'Re-inspection request',
  'hazard_escalation': 'Hazard escalation',
  'account_help': 'Account help',
  'other': 'Other',
};

const ticketStatuses = <String, String>{
  'open': 'Open',
  'in_progress': 'In progress',
  'resolved': 'Resolved',
  'closed': 'Closed',
};

const ticketDescriptionMin = 10;
const ticketDescriptionMax = 2000;

class SupportTicket {
  const SupportTicket({
    required this.id,
    required this.reference,
    required this.category,
    required this.description,
    required this.status,
    required this.createdAt,
    this.reportId,
    this.response,
    this.respondedAt,
  });

  final String id;
  final String reference;
  final String category;
  final String description;
  final String status;
  final DateTime createdAt;
  final String? reportId;
  final String? response;
  final DateTime? respondedAt;

  String get categoryLabel => ticketCategories[category] ?? 'Other';
  String get statusLabel => ticketStatuses[status] ?? 'Open';
  bool get hasReply => (response ?? '').trim().isNotEmpty;

  factory SupportTicket.fromJson(Map<String, dynamic> json) => SupportTicket(
    id: json['id'] as String,
    reference: json['reference'] as String,
    category: json['category'] as String? ?? 'other',
    description: json['description'] as String? ?? '',
    status: json['status'] as String? ?? 'open',
    createdAt: DateTime.parse(json['created_at'] as String),
    reportId: json['report_id'] as String?,
    response: json['response'] as String?,
    respondedAt: json['responded_at'] == null
        ? null
        : DateTime.parse(json['responded_at'] as String),
  );
}

class SupportTicketPage {
  const SupportTicketPage({required this.tickets, this.nextCursor});

  final List<SupportTicket> tickets;
  final Map<String, String>? nextCursor;

  factory SupportTicketPage.fromJson(Map<String, dynamic> json) {
    final cursor = json['next_cursor'];
    return SupportTicketPage(
      tickets: (json['tickets'] as List)
          .map((item) => SupportTicket.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
      nextCursor: cursor is Map
          ? {
              'before_created': cursor['created_at'] as String,
              'before_id': cursor['id'] as String,
            }
          : null,
    );
  }
}

/// Plain-language failure for a ticket request; the server's message is already citizen-safe.
class SupportTicketException implements Exception {
  const SupportTicketException(this.message);
  final String message;
  @override
  String toString() => message;
}
