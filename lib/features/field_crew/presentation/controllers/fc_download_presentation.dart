import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ecopin_app/features/field_crew/offline/fc_offline_package.dart';

/// Which of the download screen's states the crew is in.
enum FcDownloadKind { none, downloading, ready, gaps, earlier, failed }

/// What the status card at the top of “Download your jobs” says and offers.
class FcDownloadStatus {
  const FcDownloadStatus({
    required this.kind,
    required this.title,
    required this.detail,
    required this.icon,
    this.actionLabel,
    this.primary = false,
    this.progress,
    this.showSignalNote = false,
  });

  final FcDownloadKind kind;
  final String title;
  final String detail;
  final IconData icon;

  /// Null while a download runs: there is nothing to press.
  final String? actionLabel;

  /// Primary when the crew should act before leaving, quiet when all is well.
  final bool primary;

  /// Null shows no bar; a value is the share of steps finished.
  final double? progress;

  /// The one line about what a download does not include.
  final bool showSignalNote;
}

const fcDownloadSignalNote = 'Full-size photos and the map still need signal.';

/// Plain names for the six steps. The stored labels stay as they are, so a
/// saved receipt from an earlier version still matches.
String fcStepName(String label) => switch (label) {
  FcOfflineStepLabel.tasks => 'Your jobs',
  FcOfflineStepLabel.reports => 'Reports in your jobs',
  FcOfflineStepLabel.evidence => 'Photo and evidence details',
  FcOfflineStepLabel.notes => 'Notes',
  FcOfflineStepLabel.issueTypes => 'Report types',
  FcOfflineStepLabel.routes => 'Your route',
  _ => label,
};

/// The written state of one step.
String fcStepState(FcDownloadStep step) => step.error != null
    ? 'Needs another try'
    : step.completed
    ? step.label == FcOfflineStepLabel.issueTypes
          ? 'Already in the app'
          : 'Done'
    : step.inProgress
    ? 'Downloading'
    : 'Waiting';

int fcStepsDone(FcOfflinePackageState state) =>
    state.steps.where((s) => s.completed && s.error == null).length;

int fcStepGaps(FcOfflinePackageState state) =>
    state.steps.where((s) => s.error != null).length;

/// “today, 2:14 PM”, “yesterday, 7:40 AM”, or “Nov 2, 2:14 PM”.
String fcDownloadedWhen(DateTime? value, {DateTime? now}) {
  if (value == null) return 'Downloaded';
  final local = value.toLocal();
  final today = (now ?? DateTime.now()).toLocal();
  final day = DateTime(local.year, local.month, local.day);
  final base = DateTime(today.year, today.month, today.day);
  final time = DateFormat.jm().format(local);
  final days = base.difference(day).inDays;
  if (days == 0) return 'Downloaded today, $time';
  if (days == 1) return 'Downloaded yesterday, $time';
  return 'Downloaded ${DateFormat.MMMd().format(local)}, $time';
}

String _count(int n, String one, String many) => '$n ${n == 1 ? one : many}';

/// “2 jobs · 8 reports”, for the closed row.
String fcContentsSummary(FcOfflinePackageState state) {
  if (!state.isReady &&
      state.taskCount + state.reportCount + state.evidenceCount == 0) {
    return 'Nothing yet';
  }
  return '${_count(state.taskCount, 'job', 'jobs')} · ${_count(state.reportCount, 'report', 'reports')}';
}

/// “6 of 6 done”, “1 needs another try”, or where it stands before a download.
String fcStepsSummary(FcOfflinePackageState state) {
  if (state.steps.isEmpty) return state.isReady ? 'Not checked' : 'Not started';
  final gaps = fcStepGaps(state);
  if (gaps > 0) return '$gaps ${gaps == 1 ? 'needs' : 'need'} another try';
  return '${fcStepsDone(state)} of ${state.steps.length} done';
}

FcDownloadStatus fcDownloadStatus(
  FcOfflinePackageState state, {
  DateTime? now,
}) {
  final total = state.steps.length;
  final done = fcStepsDone(state);
  final gaps = fcStepGaps(state);
  if (state.isDownloading) {
    final current = state.steps.indexWhere((s) => s.inProgress);
    final number = (current >= 0 ? current : done).clamp(
      0,
      total == 0 ? 0 : total - 1,
    );
    final estimating = state.phase == FcOfflinePackagePhase.estimating;
    return FcDownloadStatus(
      kind: FcDownloadKind.downloading,
      title: 'Downloading your jobs',
      detail: estimating || total == 0
          ? 'Checking how much space is needed.'
          : 'Step ${number + 1} of $total: ${fcStepName(state.steps[number].label)}',
      icon: Icons.downloading,
      progress: estimating || total == 0 ? null : done / total,
    );
  }
  if (state.isReady) {
    final when = fcDownloadedWhen(state.preparedAt, now: now);
    if (gaps > 0) {
      return FcDownloadStatus(
        kind: FcDownloadKind.gaps,
        title: 'Some information did not download',
        detail:
            '$gaps of $total parts ${gaps == 1 ? 'needs' : 'need'} another try. Connect and download again before you leave.',
        icon: Icons.warning_amber_rounded,
        actionLabel: 'Download again',
        primary: true,
        showSignalNote: true,
      );
    }
    final verified = total > 0 && done == total;
    if (!verified) {
      return FcDownloadStatus(
        kind: FcDownloadKind.earlier,
        title: 'Jobs saved earlier',
        detail: '$when. Download again to check that nothing is missing.',
        icon: Icons.history,
        actionLabel: 'Download again',
        primary: true,
        showSignalNote: true,
      );
    }
    final jobs = state.taskCount == 0 && state.reportCount == 0
        ? 'No jobs are assigned to you right now.'
        : '${_count(state.taskCount, 'job', 'jobs')} and ${_count(state.reportCount, 'report', 'reports')}.';
    return FcDownloadStatus(
      kind: FcDownloadKind.ready,
      title: 'Your jobs are on this phone',
      detail: '$when. $jobs',
      icon: Icons.check_circle_outline,
      actionLabel: 'Download again',
      showSignalNote: true,
    );
  }
  if (state.phase == FcOfflinePackagePhase.failed) {
    return const FcDownloadStatus(
      kind: FcDownloadKind.failed,
      title: 'Download did not finish',
      detail:
          'Check your signal and try again. What already downloaded is still on this phone.',
      icon: Icons.error_outline,
      actionLabel: 'Try again',
      primary: true,
    );
  }
  return const FcDownloadStatus(
    kind: FcDownloadKind.none,
    title: 'Your jobs are not on this phone yet',
    detail:
        'Download them while you have signal. Then you can open them with no signal.',
    icon: Icons.download_for_offline_outlined,
    actionLabel: 'Download jobs',
    primary: true,
    showSignalNote: true,
  );
}
