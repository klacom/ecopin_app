import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/shared/profile/providers/profile_provider.dart';

class FcMetricsHeader extends ConsumerWidget {
  const FcMetricsHeader({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(profileProvider).value?['full_name'];
    final firstName = name is String && name.trim().isNotEmpty
        ? name.trim().split(RegExp(r'\s+')).first
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            firstName == null ? 'Your assigned work' : 'Hello, $firstName',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
      ],
    );
  }
}
