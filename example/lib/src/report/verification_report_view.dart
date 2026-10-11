import 'package:flutter/material.dart';
import 'package:ua_cryptography/ua_cryptography.dart';

import '../widgets/facts_table.dart';
import '../widgets/formatting.dart';
import '../widgets/section_card.dart';
import '../widgets/status_banner.dart';

/// The verdict banner, the container's problems, and one card per signature.
class VerificationReportView extends StatelessWidget {
  final VerificationSummary report;
  final String fileName;

  const VerificationReportView({super.key, required this.report, required this.fileName});

  @override
  Widget build(BuildContext context) {
    final signatures = report.signatures.where((summary) => !summary.isContainer).toList();
    final container = report.signatures.where((summary) => summary.isContainer).firstOrNull;
    final tone = !report.isValid
        ? BannerTone.failure
        : report.hasWarnings
        ? BannerTone.warning
        : BannerTone.ok;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StatusBanner(
          tone: tone,
          title: report.isValid ? 'The signature is valid' : 'The signature is NOT valid',
          lines: [
            switch (tone) {
              BannerTone.failure => 'At least one check failed — see the marked items below.',
              BannerTone.warning =>
                'Some things could not be established (usually the revocation status of a certificate); '
                    'see "Attention".',
              _ => 'Every check passed.',
            },
            '$fileName — ${report.format}, ${signatures.length} signature${signatures.length == 1 ? '' : 's'}',
          ],
        ),
        const SizedBox(height: 16),
        if (container != null && container.checks.any((check) => check.status != CheckOutcome.passed))
          SectionCard(title: 'Container', children: [CheckList(container.checks)]),
        for (final summary in signatures) SignatureCard(summary),
      ],
    );
  }
}

/// One signature: who signed, when, with what, and every check.
class SignatureCard extends StatelessWidget {
  final SignatureSummary summary;

  const SignatureCard(this.summary, {super.key});

  @override
  Widget build(BuildContext context) {
    final signer = summary.signer;
    final problems = summary.checks.where((check) => check.status != CheckOutcome.passed).toList();
    final (pillLabel, pillTone) = !summary.isValid
        ? ('INVALID', BannerTone.failure)
        : summary.hasWarnings
        ? ('VALID, WITH WARNINGS', BannerTone.warning)
        : ('VALID', BannerTone.ok);
    final format = [?summary.level, ?summary.packaging, ?summary.digestAlgorithm?.name].join(', ');
    return SectionCard(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                signer?.subjectName ?? summary.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            _Pill(pillLabel, pillTone),
          ],
        ),
        const SizedBox(height: 12),
        FactsTable([
          if (format.isNotEmpty) ('Format', format),
          if (summary.signatureAlgorithm case final algorithm?) ('Algorithm', algorithm.name),
          if (summary.signingTime case final time?)
            ('Signed at', "${formatTime(time)} (as the signer's computer says)"),
          if (summary.timestampTime case final time?) ('Time-stamp', '${formatTime(time)} (time-stamp, verified)'),
          if (signer?.subjectAttribute('O') case final organization?) ('Organization', organization),
          if (signer?.subjectAttribute('SERIALNUMBER') case final identifier?) ('Identifier', identifier),
          if (signer != null) ('Issued by', signer.issuerName),
          if (signer != null) ('Certificate valid', '${formatDay(signer.validFrom)} – ${formatDay(signer.validTo)}'),
          ('Signature', summary.title),
        ]),
        if (problems.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('ATTENTION', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          CheckList(problems),
        ],
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: Text('All checks (${summary.checks.length})'),
          children: [CheckList(summary.checks)],
        ),
        if (summary.references.isNotEmpty)
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('Signed digests'),
            children: [
              FactsTable([
                for (final reference in summary.references)
                  (reference.name, '${reference.digestAlgorithm.name} ${reference.digest}'),
              ]),
            ],
          ),
      ],
    );
  }
}

/// Checks with their marks: ✓ passed, ! warning, ✗ failed.
class CheckList extends StatelessWidget {
  final List<VerificationCheck> checks;

  const CheckList(this.checks, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final check in checks)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 20,
                  child: Text(
                    switch (check.status) {
                      CheckOutcome.passed => '✓',
                      CheckOutcome.warning => '!',
                      CheckOutcome.failed => '✗',
                    },
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: switch (check.status) {
                        CheckOutcome.passed => const Color(0xFF1E6B34),
                        CheckOutcome.warning => const Color(0xFF8A5A00),
                        CheckOutcome.failed => const Color(0xFFA11B1B),
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: SelectableText.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: check.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        TextSpan(text: ': ${check.details}'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final BannerTone tone;

  const _Pill(this.label, this.tone);

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (tone) {
      BannerTone.ok => (const Color(0xFFE6F4EA), const Color(0xFF1E6B34)),
      BannerTone.warning => (const Color(0xFFFFF4DC), const Color(0xFF8A5A00)),
      _ => (const Color(0xFFFDE7E7), const Color(0xFFA11B1B)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(12)),
      child: Text(
        label,
        style: TextStyle(color: foreground, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}
