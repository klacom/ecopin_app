import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/colors.dart';

class PasswordRequirement {
  final bool isMet;
  final String text;

  PasswordRequirement({required this.isMet, required this.text});
}

class PasswordStrengthMeter extends StatelessWidget {
  final String password;
  final Map<String, dynamic>? requirements;

  const PasswordStrengthMeter({
    super.key,
    required this.password,
    this.requirements,
  });

  List<PasswordRequirement> _getRequirements() {
    if (requirements == null) return [];

    final minLength = requirements!['password_min_length'] ?? 8;
    final hasUpperCase = RegExp(r'[A-Z]').hasMatch(password);
    final hasLowerCase = RegExp(r'[a-z]').hasMatch(password);
    final hasNumbers = RegExp(r'\d').hasMatch(password);
    final hasSpecialChar = RegExp(r'[!@#\$%\^&\*\(\),\.\?":\{\}\|<>]').hasMatch(password);

    List<PasswordRequirement> reqs = [
      PasswordRequirement(
        isMet: password.length >= minLength,
        text: 'At least $minLength characters long',
      ),
    ];

    if (requirements!['password_require_uppercase'] == true) {
      reqs.add(PasswordRequirement(isMet: hasUpperCase, text: 'At least one uppercase letter'));
    }
    if (requirements!['password_require_lowercase'] == true) {
      reqs.add(PasswordRequirement(isMet: hasLowerCase, text: 'At least one lowercase letter'));
    }
    if (requirements!['password_require_numbers'] == true) {
      reqs.add(PasswordRequirement(isMet: hasNumbers, text: 'At least one number'));
    }
    if (requirements!['password_require_special_chars'] == true) {
      reqs.add(PasswordRequirement(isMet: hasSpecialChar, text: 'At least one special character'));
    }

    return reqs;
  }

  @override
  Widget build(BuildContext context) {
    final reqs = _getRequirements();
    if (reqs.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppColors.spaceSM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: reqs.map((req) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Row(
              children: [
                Icon(
                  req.isMet ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 16,
                  color: req.isMet ? AppColors.success : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  req.text,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: req.isMet 
                        ? (Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                        : Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
