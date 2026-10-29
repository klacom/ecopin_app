class OfficialContactSettings {
  const OfficialContactSettings([this.cms = const {}]);
  final Map<String, dynamic> cms;

  static String? dial(String value) {
    if (value.length > 40 || !RegExp(r'^\+?[\d ()-]+$').hasMatch(value)) {
      return null;
    }
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (!RegExp(r'^\d{3,15}$').hasMatch(digits)) return null;
    final number = value.startsWith('+')
        ? '+$digits'
        : digits.startsWith('0') && digits.length >= 10
        ? '+63${digits.substring(1)}'
        : digits;
    return 'tel:$number';
  }

  String _phone(String key, String fallback) {
    final value = cms[key];
    return value is String && dial(value) != null ? value : fallback;
  }

  String _source(String key, String fallback) {
    final value = cms[key];
    final uri = value is String ? Uri.tryParse(value) : null;
    return uri != null &&
            uri.scheme == 'https' &&
            uri.host.isNotEmpty &&
            uri.userInfo.isEmpty
        ? value as String
        : fallback;
  }

  String get phone => _phone('contact_phone', '(02) 8643-1111');
  String get emergency => _phone('contact_emergency_phone', '(02) 8643-0000');
  String get office =>
      cms['contact_office_name'] is String &&
          (cms['contact_office_name'] as String).trim().isNotEmpty
      ? cms['contact_office_name'] as String
      : 'Pasig Solid Waste Management Office (SWMO)';
  String get extension =>
      cms['contact_swmo_extension'] is String &&
          RegExp(r'^\d{0,8}$').hasMatch(cms['contact_swmo_extension'] as String)
      ? cms['contact_swmo_extension'] as String
      : '1392';
  String get email {
    final value = cms['contact_office_email'] ?? 'swmo@pasigcity.gov.ph';
    return value is String &&
            RegExp(r'^[^\s@?&#]+@[^\s@?&#]+\.[^\s@?&#]+$').hasMatch(value)
        ? value
        : '';
  }

  String get directory => _source(
    'contact_directory_url',
    'https://pasigcity.gov.ph/about-pasig-city/directory',
  );
  String get emergencySource =>
      _source('contact_emergency_source_url', 'https://pasigcity.gov.ph/');
  String get verified => cms.containsKey('contact_verified_on')
      ? (cms['contact_verified_on'] is String
            ? cms['contact_verified_on'] as String
            : '')
      : '2026-10-29';
}
