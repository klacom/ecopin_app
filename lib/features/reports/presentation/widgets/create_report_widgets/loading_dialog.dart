import 'dart:async';
import 'package:flutter/material.dart';

class LoadingDialog extends StatefulWidget {
  final List<String> funFacts;

  const LoadingDialog({super.key, required this.funFacts});

  @override
  State<LoadingDialog> createState() => LoadingDialogState();
}

class LoadingDialogState extends State<LoadingDialog> {
  int _currentFactIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      setState(() {
        _currentFactIndex = (_currentFactIndex + 1) % widget.funFacts.length;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            const Text(
              "Submitting your report...",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (child, animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: Text(
                widget.funFacts[_currentFactIndex],
                key: ValueKey(_currentFactIndex),
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
