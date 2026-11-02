import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/features/field_crew/offline/fc_offline_package_notifier.dart';
import '../controllers/fc_download_presentation.dart';
import '../widgets/fc_offline_package_details.dart';
import '../widgets/fc_offline_ui.dart';
import '../widgets/fc_status_card.dart';
import '../widgets/fc_sync_section.dart';

/// “Download your jobs”: one status card that says whether the jobs are on
/// this phone and offers the one button, then two closed rows for the details.
/// The route and class names keep their old “prepare offline” spelling.
class FieldCrewPrepareOfflineScreen extends ConsumerStatefulWidget {
  const FieldCrewPrepareOfflineScreen({super.key});
  @override
  ConsumerState<FieldCrewPrepareOfflineScreen> createState() =>
      _FieldCrewPrepareOfflineScreenState();
}

class _FieldCrewPrepareOfflineScreenState
    extends ConsumerState<FieldCrewPrepareOfflineScreen> {
  bool _contentsOpen = false;

  /// Null until the crew taps the row: then it follows whether a step needs
  /// another try, so a problem is never hidden behind a closed row.
  bool? _stepsOpen;

  @override
  Widget build(BuildContext context) {
    final package = ref.watch(fcOfflinePackageNotifierProvider);
    final status = fcDownloadStatus(package);
    final gaps = fcStepGaps(package) > 0;
    return Scaffold(
      appBar: AppBar(title: const Text('Download your jobs')),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              FcStatusCard(
                tone: switch (status.kind) {
                  FcDownloadKind.ready => FcStatusTone.success,
                  FcDownloadKind.gaps ||
                  FcDownloadKind.earlier => FcStatusTone.warning,
                  FcDownloadKind.failed => FcStatusTone.error,
                  _ => FcStatusTone.accent,
                },
                icon: status.icon,
                title: status.title,
                detail: status.detail,
                showProgress: status.kind == FcDownloadKind.downloading,
                progress: status.progress,
                actionLabel: status.actionLabel,
                primary: status.primary,
                onAction: () => ref
                    .read(fcOfflinePackageNotifierProvider.notifier)
                    .prepare(),
                footnote: status.showSignalNote ? fcDownloadSignalNote : null,
              ),
              if (package.isReady && package.errorMessage != null)
                const FcOfflineNotice(
                  error: true,
                  message:
                      'Your jobs downloaded, but the phone could not save the download details. Download again before you leave.',
                ),
              FcOfflineCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FcSyncSection(
                      icon: Icons.inventory_2_outlined,
                      title: 'What is on this phone',
                      summary: fcContentsSummary(package),
                      open: _contentsOpen,
                      onToggle: () =>
                          setState(() => _contentsOpen = !_contentsOpen),
                      child: FcDownloadContents(state: package),
                    ),
                    const Divider(height: 1),
                    FcSyncSection(
                      icon: Icons.checklist,
                      title: 'Download steps',
                      summary: fcStepsSummary(package),
                      open: _stepsOpen ?? gaps,
                      onToggle: () =>
                          setState(() => _stepsOpen = !(_stepsOpen ?? gaps)),
                      child: FcDownloadSteps(state: package),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
