import 'package:flutter/material.dart';

class ReportShareButton extends StatefulWidget {
  const ReportShareButton({super.key, required this.onShare});

  final Future<void> Function() onShare;

  @override
  State<ReportShareButton> createState() => _ReportShareButtonState();
}

class _ReportShareButtonState extends State<ReportShareButton> {
  bool _isSharing = false;

  Future<void> _share() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    try {
      await widget.onShare();
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: _isSharing ? 'Preparing share…' : 'Share report',
    onPressed: _isSharing ? null : _share,
    icon: _isSharing
        ? const SizedBox.square(
            dimension: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              semanticsLabel: 'Preparing report to share',
            ),
          )
        : const Icon(Icons.share_rounded),
  );
}
