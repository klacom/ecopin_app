class PasswordPolicy {
  PasswordPolicy(this.settings) {
    if (settings['password_min_length'] is! int ||
        (settings['password_min_length'] as int) < 1 ||
        _patterns.keys.any((key) => settings[key] is! bool)) {
      throw const FormatException('Password policy unavailable');
    }
  }
  final Map<String, dynamic> settings;
  static final _patterns = {
    'password_require_uppercase': (RegExp(r'[A-Z]'), 'an uppercase letter'),
    'password_require_lowercase': (RegExp(r'[a-z]'), 'a lowercase letter'),
    'password_require_numbers': (RegExp(r'\d'), 'a number'),
    'password_require_special_chars': (
      RegExp(r'[!@#$%^&*(),.?":{}|<>]'),
      'a special character',
    ),
  };
  String? validate(String password) {
    final minimum = settings['password_min_length'] as int;
    if (password.length < minimum) return 'Use at least $minimum characters.';
    for (final entry in _patterns.entries) {
      if (settings[entry.key] == true && !entry.value.$1.hasMatch(password)) {
        return 'Include ${entry.value.$2}.';
      }
    }
    return null;
  }
}
