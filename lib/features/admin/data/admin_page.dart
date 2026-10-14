class AdminPage {
  const AdminPage(this.records, this.page, this.total, this.totalPages);
  final List<Map<String, dynamic>> records;
  final int page;
  final int? total, totalPages;
  factory AdminPage.fromResponse(
    Map<String, dynamic> response,
    String key,
    int requestedPage,
  ) {
    final records = response[key];
    if (records is! List || records.any((row) => row is! Map)) {
      throw const FormatException('Admin list unavailable');
    }
    final pagination = response['pagination'];
    int? number(String key) {
      final value = pagination is Map ? pagination[key] : null;
      return value is int && value >= 0 ? value : null;
    }

    return AdminPage(
      records.map((row) => Map<String, dynamic>.from(row as Map)).toList(),
      (number('page') ?? 0) > 0 ? number('page')! : requestedPage,
      number('total'),
      number('totalPages'),
    );
  }
}
