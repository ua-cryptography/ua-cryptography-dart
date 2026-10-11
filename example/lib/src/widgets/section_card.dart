import 'package:flutter/material.dart';

/// A card with an optional numbered or plain heading.
class SectionCard extends StatelessWidget {
  final String? title;
  final int? step;
  final List<Widget> children;

  const SectionCard({super.key, this.title, this.step, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    if (step != null) ...[
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: theme.colorScheme.primary,
                        child: Text('$step', style: TextStyle(color: theme.colorScheme.onPrimary, fontSize: 13)),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(title!, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ...children,
          ],
        ),
      ),
    );
  }
}
