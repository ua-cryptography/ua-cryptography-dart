import 'package:flutter/material.dart';

/// The tone of a banner: success, a warning that leaves the result standing, a failure, or work in progress.
enum BannerTone { ok, warning, failure, busy }

/// A coloured banner with a mark, a headline and optional lines below it.
class StatusBanner extends StatelessWidget {
  final BannerTone tone;
  final String title;
  final List<String> lines;
  final Widget? action;

  const StatusBanner({super.key, required this.tone, required this.title, this.lines = const [], this.action});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (background, foreground, icon) = switch (tone) {
      BannerTone.ok => (const Color(0xFFE6F4EA), const Color(0xFF1E6B34), Icons.check_circle_outline),
      BannerTone.warning => (const Color(0xFFFFF4DC), const Color(0xFF8A5A00), Icons.check_circle_outline),
      BannerTone.failure => (const Color(0xFFFDE7E7), const Color(0xFFA11B1B), Icons.cancel_outlined),
      BannerTone.busy => (scheme.surfaceContainerHigh, scheme.onSurface, Icons.hourglass_top),
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          tone == BannerTone.busy
              ? const SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2.5))
              : Icon(icon, color: foreground),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: foreground, fontWeight: FontWeight.w600),
                ),
                for (final line in lines) Padding(padding: const EdgeInsets.only(top: 4), child: SelectableText(line)),
                if (action != null) Padding(padding: const EdgeInsets.only(top: 8), child: action),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
