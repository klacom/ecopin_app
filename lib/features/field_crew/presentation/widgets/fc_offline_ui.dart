import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:intl/intl.dart';

String fcLocalTime(DateTime value) =>
    '${DateFormat.yMMMd().add_jm().format(value.toLocal())} (local time)';

class FcOfflineCard extends StatelessWidget {
  const FcOfflineCard({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppColors.radiusCard),
      side: BorderSide(
        color:
            Theme.of(context).dividerTheme.color ??
            Theme.of(context).dividerColor,
      ),
    ),
    child: Padding(padding: const EdgeInsets.all(20), child: child),
  );
}

class FcOfflineFact extends StatelessWidget {
  const FcOfflineFact(this.label, this.value, {super.key});
  final String label, value;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final text = Theme.of(context).textTheme;
      final compact =
          constraints.maxWidth >= 200 &&
          MediaQuery.textScalerOf(context).scale(14) <= 18 &&
          value.length <= 18;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: compact
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: Text(label, style: text.bodySmall)),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Text(
                      value,
                      textAlign: TextAlign.end,
                      style: text.titleSmall,
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(label, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Text(value, style: Theme.of(context).textTheme.titleSmall),
                ],
              ),
      );
    },
  );
}

class FcOfflineNotice extends StatelessWidget {
  const FcOfflineNotice({
    super.key,
    required this.message,
    this.action,
    this.error = false,
  });
  final String message;
  final Widget? action;
  final bool error;
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: FcOfflineCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                error ? Icons.error_outline : Icons.info_outline,
                color: error
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.onSurface,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          if (action != null) ...[const SizedBox(height: 12), action!],
        ],
      ),
    ),
  );
}
