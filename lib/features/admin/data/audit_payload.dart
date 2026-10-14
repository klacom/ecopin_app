import 'dart:convert';

Object? _hideCredentials(Object? value) {
  if (value is Map) {
    const credentialKeys = {
      'password',
      'passwordhash',
      'accesstoken',
      'refreshtoken',
      'authorization',
      'apikey',
      'secret',
      'clientsecret',
    };
    return {
      for (final entry in value.entries)
        entry.key.toString():
            credentialKeys.contains(
              entry.key.toString().toLowerCase().replaceAll(
                RegExp('[^a-z]'),
                '',
              ),
            )
            ? '[hidden]'
            : _hideCredentials(entry.value),
    };
  }
  if (value is List) return value.map(_hideCredentials).toList();
  return value;
}

String auditPayloadText(Map<String, dynamic> entry) {
  Object? payload =
      entry['event_data'] ??
      entry['action_details'] ??
      entry['metadata'] ??
      entry['meta'] ??
      entry['details'];
  if (payload == null) return 'Unavailable';
  if (payload is String) {
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map || decoded is List) payload = decoded;
    } on FormatException {
      /* Ordinary descriptions are already plain text. */
    }
  }
  final safe = _hideCredentials(payload);
  return safe is String
      ? safe
      : const JsonEncoder.withIndent('  ').convert(safe);
}
