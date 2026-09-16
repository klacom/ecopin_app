// Shared password validation utilities.
//
// These rules mirror the backend's canonical password policy defined in
// ecopin_backend_node/src/config/index.js and enforced by
// ecopin_backend_node/src/middleware/validation.middleware.js:
//
//   MIN_PASSWORD_LENGTH = 8
//   /[A-Z]/  (at least one uppercase letter)
//   /[0-9]/  (at least one digit)
//
// Both Registration and Change Password flows use these functions so that
// the frontend and backend never drift independently.
library;

const int _minPasswordLength = 8;

/// Returns `null` when [password] satisfies every backend requirement.
/// Returns a human-readable error message describing the *first* unmet rule.
String? validatePassword(String password) {
  if (password.length < _minPasswordLength) {
    return 'Password must be at least $_minPasswordLength characters';
  }
  if (!password.contains(RegExp(r'[A-Z]'))) {
    return 'Password must contain at least one uppercase letter';
  }
  if (!password.contains(RegExp(r'[0-9]'))) {
    return 'Password must contain at least one number';
  }
  return null;
}

/// Returns `null` when [confirm] matches [password].
/// Returns an error message when they differ.
String? validateConfirmPassword(String password, String confirm) {
  if (confirm != password) return 'Passwords do not match';
  return null;
}
