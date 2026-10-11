import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:ua_cryptography/ua_cryptography.dart';

import '../report/verification_report_view.dart';
import '../trust/trust_store.dart';
import '../widgets/files.dart';
import '../widgets/formatting.dart';
import '../widgets/section_card.dart';
import '../widgets/status_banner.dart';

/// An opened key store: the key that signs and its certificate.
final class OpenedKey {
  final String fileName;
  final Uint8List keyStore;
  final String password;
  final List<String> aliases;
  final String alias;
  final Uint8List certificate;
  final CertificateDetails details;

  /// Made here by "Create a test key": its self-signed certificate is trusted for the check after signing.
  final bool isSynthetic;

  const OpenedKey({
    required this.fileName,
    required this.keyStore,
    required this.password,
    required this.aliases,
    required this.alias,
    required this.certificate,
    required this.details,
    required this.isSynthetic,
  });
}

/// Sign: open a JKS key store, choose a document, sign; the result is saved and verified on the spot.
class SignPage extends StatefulWidget {
  final TrustStore trustStore;

  const SignPage({super.key, required this.trustStore});

  @override
  State<SignPage> createState() => _SignPageState();
}

class _SignPageState extends State<SignPage> {
  static const String testKeySubject = 'CN=Тестовий підписувач,O=Synthetic Test,C=UA';
  static const String testKeyPassword = 'test-password';

  final passwordController = TextEditingController();
  NamedBytes? keyFile;
  OpenedKey? key;
  String? keyFailure;
  bool isOpening = false;

  NamedBytes? document;
  SignatureFormat format = SignatureFormat.cades;
  SignatureLevel level = SignatureLevel.b;
  SignatureHash hash = SignatureHash.dstu7564;
  bool isDetached = false;

  bool isSigning = false;
  String? signFailure;
  NamedBytes? signed;
  VerificationSummary? report;

  @override
  void dispose() {
    passwordController.dispose();
    super.dispose();
  }

  bool get hasTimeStampService => key?.details.timeStampUrls.isNotEmpty ?? false;

  Future<void> chooseKeyFile() async {
    final file = await pickFile(extensions: ['jks', 'JKS']);
    if (file != null) {
      setState(() {
        keyFile = file;
        keyFailure = null;
      });
    }
  }

  void openKey({String? alias}) {
    final file = keyFile;
    if (file == null) {
      return;
    }
    setState(() => keyFailure = null);
    try {
      key = _open(file.name, file.content, passwordController.text, alias: alias, isSynthetic: false);
      level = hasTimeStampService ? SignatureLevel.t : SignatureLevel.b;
      setState(() {});
    } on UaCryptographyException catch (refusal) {
      setState(() => keyFailure = refusal.message);
    }
  }

  Future<void> createTestKey() async {
    setState(() {
      isOpening = true;
      keyFailure = null;
    });
    try {
      final created = await createKeyStore(const KeyStoreRequest(subject: testKeySubject), testKeyPassword);
      setState(() {
        key = _open('test-key.jks', created.keyStore, testKeyPassword, isSynthetic: true);
        level = SignatureLevel.b;
      });
    } on UaCryptographyException catch (refusal) {
      setState(() => keyFailure = refusal.message);
    } finally {
      setState(() => isOpening = false);
    }
  }

  OpenedKey _open(String fileName, Uint8List keyStore, String password, {String? alias, required bool isSynthetic}) {
    final aliases = [
      for (final entry in getKeyStoreEntries(keyStore, password))
        if (entry.kind == KeyStoreEntryKind.privateKey) entry.alias,
    ];
    if (aliases.isEmpty) {
      throw const InvalidArgumentException('The key store holds no private key.');
    }
    final chosen = alias ?? aliases.first;
    final certificate = getCertificate(keyStore, password, alias: chosen);
    return OpenedKey(
      fileName: fileName,
      keyStore: keyStore,
      password: password,
      aliases: aliases,
      alias: chosen,
      certificate: certificate,
      details: getCertificateDetails(certificate),
      isSynthetic: isSynthetic,
    );
  }

  void closeKey() {
    passwordController.clear();
    setState(() {
      key = null;
      keyFile = null;
      signed = null;
      report = null;
    });
  }

  Future<void> chooseDocument() async {
    final file = await pickFile();
    if (file != null) {
      setState(() {
        document = file;
        signed = null;
        report = null;
        signFailure = null;
      });
    }
  }

  Future<void> signDocument() async {
    final openedKey = key;
    final file = document;
    if (openedKey == null || file == null) {
      return;
    }
    setState(() {
      isSigning = true;
      signFailure = null;
      signed = null;
      report = null;
    });
    try {
      final isDetachedCades = format == SignatureFormat.cades && isDetached;
      final signature = await sign(
        openedKey.keyStore,
        openedKey.password,
        [file],
        alias: openedKey.alias,
        options: SigningOptions(format: format, level: level, hash: hash, isDetached: isDetachedCades),
        certificates: widget.trustStore.certificates,
      );
      final result = NamedBytes(_signatureFileName(file.name), signature);
      setState(() => signed = result);
      final summary = await verify(
        signature,
        data: format == SignatureFormat.xades || isDetachedCades ? [file] : const [],
        trustAnchors: [...widget.trustStore.trustAnchors, if (openedKey.isSynthetic) openedKey.certificate],
        certificates: widget.trustStore.certificates,
      );
      setState(() => report = summary);
    } on UaCryptographyException catch (refusal) {
      setState(() => signFailure = refusal.message);
    } finally {
      setState(() => isSigning = false);
    }
  }

  String _signatureFileName(String documentName) => switch (format) {
    SignatureFormat.cades => isDetached ? '$documentName.p7s' : '$documentName.sig',
    SignatureFormat.xades => '$documentName.xml',
    SignatureFormat.asicS => '$documentName.asics',
    SignatureFormat.asicE => '$documentName.asice',
  };

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionCard(title: 'Key', step: 1, children: [key == null ? _keyForm() : _keyInfo(key!)]),
        SectionCard(title: 'Document', step: 2, children: _documentSection()),
      ],
    );
  }

  Widget _keyForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: chooseKeyFile,
              icon: const Icon(Icons.key),
              label: Text(keyFile?.name ?? 'Key store (.jks)…'),
            ),
            SizedBox(
              width: 260,
              child: TextField(
                controller: passwordController,
                obscureText: true,
                enableSuggestions: false,
                autocorrect: false,
                decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder(), isDense: true),
                onSubmitted: (_) => openKey(),
              ),
            ),
            FilledButton(onPressed: keyFile == null ? null : openKey, child: const Text('Open key')),
          ],
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: isOpening ? null : createTestKey,
            icon: const Icon(Icons.science_outlined),
            label: const Text('Or create a synthetic test key (self-signed, for trying the app)'),
          ),
        ),
        if (keyFailure case final message?)
          StatusBanner(tone: BannerTone.failure, title: 'The key does not open', lines: [message]),
      ],
    );
  }

  Widget _keyInfo(OpenedKey openedKey) {
    final details = openedKey.details;
    return StatusBanner(
      tone: BannerTone.ok,
      title: details.subjectName,
      lines: [
        'issued by ${details.issuerName} · valid ${formatDay(details.validFrom)} – ${formatDay(details.validTo)}',
        '${openedKey.fileName} · key "${openedKey.alias}" · ${details.signatureAlgorithm.name}',
        if (openedKey.isSynthetic)
          'A synthetic test key: its certificate is trusted only for the check after signing here.',
      ],
      action: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (openedKey.aliases.length > 1)
            DropdownButton<String>(
              value: openedKey.alias,
              items: [for (final alias in openedKey.aliases) DropdownMenuItem(value: alias, child: Text(alias))],
              onChanged: (alias) => openKey(alias: alias),
            ),
          if (openedKey.isSynthetic)
            OutlinedButton(
              onPressed: () => saveFile(openedKey.fileName, openedKey.keyStore),
              child: Text('Save ${openedKey.fileName} (password "$testKeyPassword")'),
            ),
          TextButton(onPressed: closeKey, child: const Text('Close the key')),
        ],
      ),
    );
  }

  List<Widget> _documentSection() {
    final openedKey = key;
    final canSign = openedKey != null && document != null && !isSigning;
    return [
      Center(
        child: Column(
          children: [
            Text(
              document == null
                  ? 'Choose the document to sign'
                  : '${document!.name} (${formatSize(document!.content.length)})',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: chooseDocument,
              icon: const Icon(Icons.description_outlined),
              label: const Text('Choose a file…'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Wrap(
        spacing: 24,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _choice<SignatureFormat>(
            'Format',
            format,
            SignatureFormat.values,
            (value) => setState(() => format = value),
            {
              SignatureFormat.cades: 'CAdES (.sig / .p7s)',
              SignatureFormat.xades: 'XAdES (.xml)',
              SignatureFormat.asicS: 'ASiC-S (.asics)',
              SignatureFormat.asicE: 'ASiC-E (.asice)',
            },
          ),
          _choice<SignatureLevel>(
            'Level',
            level,
            hasTimeStampService ? SignatureLevel.values : const [SignatureLevel.b],
            (value) => setState(() => level = value),
            {
              SignatureLevel.b: 'B — offline',
              SignatureLevel.t: 'T — with a time-stamp',
              SignatureLevel.lt: 'LT — with time-stamp, OCSP and CAs',
            },
          ),
          _choice<SignatureHash>('Hash', hash, SignatureHash.values, (value) => setState(() => hash = value), {
            SignatureHash.dstu7564: 'DSTU 7564-256 (Kupyna)',
            SignatureHash.gost34311: 'GOST 34.311-95',
          }),
          if (format == SignatureFormat.cades)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(value: isDetached, onChanged: (value) => setState(() => isDetached = value ?? false)),
                const Text('Detached (.p7s without the document inside)'),
              ],
            ),
        ],
      ),
      const SizedBox(height: 8),
      Text(
        openedKey == null
            ? 'Open a key first.'
            : hasTimeStampService
            ? 'Levels T and LT send only the hash of the signature to the time-stamping service the certificate names '
                  '(${openedKey.details.timeStampUrls.first}); the document and the key never leave this device.'
            : 'The certificate names no time-stamping service: the signature is made at level B, entirely offline.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: 12),
      Align(
        alignment: Alignment.centerLeft,
        child: FilledButton(onPressed: canSign ? signDocument : null, child: const Text('Sign')),
      ),
      const SizedBox(height: 12),
      if (isSigning) const StatusBanner(tone: BannerTone.busy, title: 'Signing…'),
      if (signFailure case final message?)
        StatusBanner(tone: BannerTone.failure, title: 'The document is not signed', lines: [message]),
      if (signed case final result?) ...[
        StatusBanner(
          tone: BannerTone.ok,
          title: 'Signed: ${result.name}',
          lines: ['${formatSize(result.content.length)}. Below is the verification of the new signature.'],
          action: FilledButton(
            onPressed: () => saveFile(result.name, result.content),
            child: Text('Save ${result.name}'),
          ),
        ),
        const SizedBox(height: 16),
      ],
      if (report case final summary?) VerificationReportView(report: summary, fileName: signed!.name),
    ];
  }

  Widget _choice<T>(String label, T value, List<T> values, ValueChanged<T> onChanged, Map<T, String> names) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label  '),
        DropdownButton<T>(
          value: values.contains(value) ? value : values.first,
          items: [for (final option in values) DropdownMenuItem(value: option, child: Text(names[option]!))],
          onChanged: (option) {
            if (option != null) {
              onChanged(option);
            }
          },
        ),
      ],
    );
  }
}
