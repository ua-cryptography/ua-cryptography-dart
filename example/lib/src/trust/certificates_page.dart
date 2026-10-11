import 'package:flutter/material.dart';
import 'package:ua_cryptography/ua_cryptography.dart';

import '../widgets/files.dart';
import '../widgets/formatting.dart';
import '../widgets/section_card.dart';
import '../widgets/status_banner.dart';
import 'trust_store.dart';

/// Certificates: the trusted roots and intermediate certificates verification relies on, and adding more.
class CertificatesPage extends StatefulWidget {
  final TrustStore trustStore;

  const CertificatesPage({super.key, required this.trustStore});

  @override
  State<CertificatesPage> createState() => _CertificatesPageState();
}

class _CertificatesPageState extends State<CertificatesPage> {
  static const List<String> certificateExtensions = ['cer', 'crt', 'der', 'pem', 'p7b', 'p7c'];

  (BannerTone, String)? message;

  Future<void> addCertificates(TrustRole role) async {
    final files = await pickFiles(extensions: certificateExtensions);
    if (files.isEmpty) {
      return;
    }
    var added = 0;
    final failed = <String>[];
    for (final file in files) {
      try {
        added += await widget.trustStore.addFile(file.content, role);
      } on Object {
        failed.add(file.name);
      }
    }
    setState(() {
      message = failed.isEmpty
          ? (BannerTone.ok, 'Added $added certificate${added == 1 ? '' : 's'}.')
          : (BannerTone.failure, 'No certificate in ${failed.join(', ')}; added $added.');
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.trustStore,
      builder: (context, _) {
        final entries = widget.trustStore.entries;
        final roots = entries.where((entry) => entry.role == TrustRole.root).toList();
        final intermediates = entries.where((entry) => entry.role == TrustRole.intermediate).toList();
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SectionCard(
              title: 'Add certificates',
              children: [
                const Text('DER or PEM .cer / .crt, or a bundle .p7b. Added certificates are kept on this device.'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: () => addCertificates(TrustRole.root),
                      icon: const Icon(Icons.verified_user_outlined),
                      label: const Text('Trusted root…'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () => addCertificates(TrustRole.intermediate),
                      icon: const Icon(Icons.account_tree_outlined),
                      label: const Text('Intermediate…'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Only add a root you have checked yourself. Intermediates are a provider's CA, TSP or OCSP "
                  'certificates.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (message case (final tone, final text)) ...[
                  const SizedBox(height: 12),
                  StatusBanner(tone: tone, title: text),
                ],
              ],
            ),
            SectionCard(
              title: 'Trusted roots (${roots.length})',
              children: [
                const Text('A signature is trusted when its certificate path ends at one of these.'),
                for (final entry in roots) _CertificateTile(entry, widget.trustStore),
              ],
            ),
            SectionCard(
              title: 'Intermediate certificates (${intermediates.length})',
              children: [
                const Text(
                  'Used to complete paths and to find time-stamping services that a signature does not carry '
                  "(a PrivatBank .sig has neither its CA's nor its TSP server's certificate).",
                ),
                for (final entry in intermediates) _CertificateTile(entry, widget.trustStore),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'ua_cryptography · native library ${getVersion()}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CertificateTile extends StatelessWidget {
  final TrustedCertificate entry;
  final TrustStore trustStore;

  const _CertificateTile(this.entry, this.trustStore);

  @override
  Widget build(BuildContext context) {
    final CertificateDetails details = entry.details;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(details.subjectName),
      subtitle: Text(
        '${details.issuer == details.subject ? 'self-signed' : 'issued by ${details.issuerName}'} · '
        '${formatDay(details.validFrom)} – ${formatDay(details.validTo)} · ${details.signatureAlgorithm.name} · '
        '${entry.isBuiltIn ? 'built in (${entry.source})' : 'added'}',
      ),
      trailing: entry.isBuiltIn
          ? null
          : IconButton(
              tooltip: 'Remove',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => trustStore.remove(entry),
            ),
    );
  }
}
