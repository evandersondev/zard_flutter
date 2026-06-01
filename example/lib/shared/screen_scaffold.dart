import 'package:flutter/material.dart';

/// Standard wrapper used by every demo screen so the app feels consistent.
class ScreenScaffold extends StatelessWidget {
  const ScreenScaffold({
    required this.title,
    required this.description,
    required this.child,
    super.key,
  });

  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Small banner that prints the latest submitted payload — used by every demo.
class SubmitResult extends StatelessWidget {
  const SubmitResult({this.payload, super.key});
  final Map<String, dynamic>? payload;

  @override
  Widget build(BuildContext context) {
    if (payload == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF22C55E).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Submitted:\n$payload',
        style: const TextStyle(fontFamily: 'monospace'),
      ),
    );
  }
}
