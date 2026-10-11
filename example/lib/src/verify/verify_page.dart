import 'package:flutter/material.dart';
import 'package:ua_cryptography/ua_cryptography.dart';

import '../report/verification_report_view.dart';
import '../trust/trust_store.dart';
import '../widgets/files.dart';
import '../widgets/section_card.dart';
import '../widgets/status_banner.dart';

/// Verify: pick a signed file (and, for a detached signature, the signed files), see the report.
class VerifyPage extends StatefulWidget {
  final TrustStore trustStore;

  const VerifyPage({super.key, required this.trustStore});

  @override
  State<VerifyPage> createState() => _VerifyPageState();
}

class _VerifyPageState extends State<VerifyPage> {
  static const Set<String> signatureExtensions = {'sig', 'p7s', 'p7m', 'asice', 'sce', 'asics', 'scs', 'xml'};

  bool isOnline = false;
  bool isBusy = false;
  String? fileName;
  VerificationSummary? report;
  String? failure;

  Future<void> chooseAndVerify() async {
    final files = await pickFiles();
    if (files.isEmpty) {
      return;
    }
    // The signature is the file of a signature format; the others are the data of a detached one.
    final signature = files.firstWhere(
      (file) => signatureExtensions.contains(file.name.split('.').last.toLowerCase()),
      orElse: () => files.first,
    );
    final data = [
      for (final file in files)
        if (!identical(file, signature)) file,
    ];
    setState(() {
      isBusy = true;
      fileName = signature.name;
      report = null;
      failure = null;
    });
    try {
      final summary = await verify(
        signature.content,
        data: data,
        trustAnchors: widget.trustStore.trustAnchors,
        certificates: widget.trustStore.certificates,
        isOnline: isOnline,
      );
      setState(() => report = summary);
    } on UaCryptographyException catch (refusal) {
      setState(() => failure = refusal.message);
    } finally {
      setState(() => isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionCard(
          children: [
            Text('Choose a signed file', style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 4),
            const Text(
              '.sig / .p7s (CAdES), .asice / .asics (ASiC), .xml (XAdES). '
              'For a detached signature, choose the signed file together with it.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Center(
              child: FilledButton.tonalIcon(
                onPressed: isBusy ? null : chooseAndVerify,
                icon: const Icon(Icons.folder_open),
                label: const Text('Choose files…'),
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              value: isOnline,
              onChanged: isBusy ? null : (value) => setState(() => isOnline = value),
              title: const Text('Check the current revocation status online'),
              subtitle: const Text(
                'Asks the OCSP servers the certificates name and downloads missing CA certificates; '
                'sends certificate serial numbers, nothing of the signature or the document.',
              ),
            ),
          ],
        ),
        if (isBusy) StatusBanner(tone: BannerTone.busy, title: 'Verifying $fileName…'),
        if (failure case final message?)
          StatusBanner(tone: BannerTone.failure, title: 'Cannot verify $fileName', lines: [message]),
        if (report case final summary?) VerificationReportView(report: summary, fileName: fileName!),
        const SizedBox(height: 8),
        const ExpansionTile(
          title: Text('What is checked here, and what is not'),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '• Checked: the DSTU 4145 signature and that it covers the document; the signer\'s certificate named in '
              'the signed attributes; the time-stamp; the certificate path up to a trusted root (ЦЗО, НБУ or one you '
              'add) with validity periods; OCSP responses embedded in the signature.\n'
              '• Online, when switched on: the current status of the certificates from the OCSP servers they name, '
              'and missing CA certificates from their caIssuers addresses.\n'
              '• Offline, gaps such as a missing revocation status are shown as warnings.\n'
              '• Files are not uploaded anywhere: everything happens on this device.',
            ),
          ],
        ),
      ],
    );
  }
}
