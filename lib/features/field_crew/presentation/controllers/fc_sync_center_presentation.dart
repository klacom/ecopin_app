import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ecopin_app/features/field_crew/sync/fc_sync_gate.dart';
import 'package:ecopin_app/features/field_crew/sync/fc_sync_settings.dart';
import 'package:ecopin_app/features/field_crew/sync/fc_sync_trigger.dart';

/// What the one status card on the send screen is telling the crew.
enum FcSendKind {
  checking,
  couldNotCheck,
  sending,
  paused,
  noSignal,
  networkOff,
  problem,
  waiting,
  sent,
}

/// The single thing the status card offers to do about it.
enum FcSendAction { none, send, checkAgain, changeSettings }

class FcSendStatus {
  const FcSendStatus({
    required this.kind,
    required this.title,
    required this.detail,
    required this.icon,
    this.action = FcSendAction.none,
    this.actionLabel,
  });

  final FcSendKind kind;
  final String title;
  final String detail;
  final IconData icon;
  final FcSendAction action;
  final String? actionLabel;
}

String fcItemCount(int count) => '$count ${count == 1 ? 'item' : 'items'}';

/// Everything waiting on the phone, as one number for the crew.
int fcWaitingCount(FcPendingSummary? summary) => summary == null
    ? 0
    : summary.mutationCount + summary.photoCount + summary.pendingDeleteCount;

/// Picks the one state the crew is in. Earlier cases win: a crew that cannot
/// send is told why before being told what is waiting.
FcSendStatus fcSendStatus({
  required FcSyncState state,
  required FcSyncSettings settings,
  required FcPendingSummary? summary,
  required bool queueFailed,
  required FcNetworkType? network,
  required bool networkLoading,
  required bool networkFailed,
  required int failureCount,
  required bool busy,
}) {
  if (busy || state.phase == FcSyncPhase.syncing) {
    return const FcSendStatus(
      kind: FcSendKind.sending,
      title: 'Sending your work',
      detail: 'Photos can take a little longer.',
      icon: Icons.sync,
    );
  }
  if (summary == null) {
    return queueFailed
        ? const FcSendStatus(
            kind: FcSendKind.couldNotCheck,
            title: 'Could not check your saved work',
            detail: 'Your work is still saved on this phone.',
            icon: Icons.sync_problem,
            action: FcSendAction.checkAgain,
            actionLabel: 'Check again',
          )
        : const FcSendStatus(
            kind: FcSendKind.checking,
            title: 'Checking your saved work',
            detail: 'One moment.',
            icon: Icons.sync,
          );
  }
  final waiting = fcWaitingCount(summary);
  final stale = queueFailed ? ' These counts may be out of date.' : '';
  if (settings.syncBlocked) {
    return FcSendStatus(
      kind: FcSendKind.paused,
      title: 'Sending is paused',
      detail: waiting == 0
          ? 'Nothing is waiting to send.$stale'
          : '${fcItemCount(waiting)} will stay on this phone until you change this.$stale',
      icon: Icons.pause_circle_outline,
      action: FcSendAction.changeSettings,
      actionLabel: 'Change how work is sent',
    );
  }
  if (networkFailed) {
    return const FcSendStatus(
      kind: FcSendKind.couldNotCheck,
      title: 'Could not check your connection',
      detail: 'Your work is still saved on this phone.',
      icon: Icons.sync_problem,
      action: FcSendAction.checkAgain,
      actionLabel: 'Check again',
    );
  }
  if (networkLoading || network == null) {
    return const FcSendStatus(
      kind: FcSendKind.checking,
      title: 'Checking your connection',
      detail: 'One moment.',
      icon: Icons.sync,
    );
  }
  if (network == FcNetworkType.none) {
    return FcSendStatus(
      kind: FcSendKind.noSignal,
      title: 'No signal',
      detail: waiting == 0
          ? 'Nothing is waiting to send.$stale'
          : '${fcItemCount(waiting)} ${waiting == 1 ? 'is' : 'are'} saved on this phone. ${waiting == 1 ? 'It' : 'They'} will send when you have Wi-Fi or mobile data.$stale',
      icon: Icons.cloud_off_outlined,
      action: FcSendAction.checkAgain,
      actionLabel: 'Check signal again',
    );
  }
  final connection = network == FcNetworkType.wifi ? 'Wi-Fi' : 'mobile data';
  final allowed = network == FcNetworkType.wifi
      ? settings.syncOverWifi
      : settings.syncOverMobileData;
  if (!allowed) {
    return FcSendStatus(
      kind: FcSendKind.networkOff,
      title: 'Sending is off on this connection',
      detail:
          'You are on $connection, and sending over $connection is turned off. Your work stays on this phone.$stale',
      icon: Icons.signal_cellular_connected_no_internet_0_bar,
      action: FcSendAction.changeSettings,
      actionLabel: 'Change how work is sent',
    );
  }
  if (waiting == 0 && failureCount == 0) {
    return FcSendStatus(
      kind: FcSendKind.sent,
      title: 'All your work is sent',
      detail: 'Nothing is waiting on this phone.$stale',
      icon: Icons.check_circle_outline,
    );
  }
  final problems = failureCount > 0
      ? failureCount
      : summary.failedPhotoCount > 0
      ? summary.failedPhotoCount
      : state.phase == FcSyncPhase.partialFailure
      ? waiting
      : 0;
  if (state.phase == FcSyncPhase.error) {
    return FcSendStatus(
      kind: FcSendKind.problem,
      title: 'Sending did not finish',
      detail:
          'Something went wrong while sending. Your work is still saved on this phone.',
      icon: Icons.error_outline,
      action: FcSendAction.send,
      actionLabel: 'Try again',
    );
  }
  if (problems > 0) {
    return FcSendStatus(
      kind: FcSendKind.problem,
      title: '${fcItemCount(problems)} did not send',
      detail:
          '${problems == 1 ? 'This item is' : 'These items are'} still on your phone.$stale',
      icon: Icons.error_outline,
      action: waiting > 0 ? FcSendAction.send : FcSendAction.none,
      actionLabel: 'Try again',
    );
  }
  final one = waiting == 1;
  final next = settings.mode == FcSyncMode.manualCommit
      ? 'Tap Send now to send ${one ? 'it' : 'them'}.'
      : '${one ? 'It' : 'They'} will send on ${one ? 'its' : 'their'} own.';
  return FcSendStatus(
    kind: FcSendKind.waiting,
    title: '${fcItemCount(waiting)} waiting to send',
    detail: 'You are on $connection. $next$stale',
    icon: Icons.sync,
    action: FcSendAction.send,
    actionLabel: 'Send now',
  );
}

/// “Send on its own · Wi-Fi only”, for the closed settings row.
String fcSendingSummary(FcSyncSettings settings) {
  final networks = settings.syncOverWifi && settings.syncOverMobileData
      ? 'Wi-Fi and mobile data'
      : settings.syncOverWifi
      ? 'Wi-Fi only'
      : settings.syncOverMobileData
      ? 'Mobile data only'
      : 'No network allowed';
  return settings.syncBlocked
      ? settings.mode.title
      : '${settings.mode.title} · $networks';
}

/// Short local time for a closed row, e.g. “Nov 2, 2:14 PM”.
String fcShortTime(DateTime value) =>
    DateFormat.MMMd().add_jm().format(value.toLocal());

/// One plain sentence for a stored failure reason. The server's own words stay
/// available under Details.
String fcPlainFailure(String reason) {
  final lower = reason.toLowerCase();
  if (lower.startsWith('permanent') || lower.startsWith('terminal_')) {
    return 'The server did not accept this. Ask the office if it keeps happening.';
  }
  if (lower.contains('503') ||
      lower.contains('database update') ||
      lower.contains('server needs')) {
    return 'The server is not ready for this yet. It stays on your phone and can try again.';
  }
  if (lower.contains('timeout') ||
      lower.contains('timed out') ||
      lower.contains('socket') ||
      lower.contains('connection')) {
    return 'The connection dropped. It can try again when the signal is good.';
  }
  return 'This did not send. It is still saved on your phone.';
}
