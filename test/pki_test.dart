import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:ua_cryptography/ua_cryptography.dart';

// Synthetic keys only, generated per run: no real key, certificate or signature of a person.
const String password = 'synthetic-password';
const String subject = 'CN=Тестовий підписувач,O=Synthetic Test,C=UA';

void main() {
  late CreatedKeyStore created;
  final document = NamedBytes('document.txt', Uint8List.fromList(utf8.encode('Тестовий документ\n')));

  setUpAll(() async {
    created = await createKeyStore(const KeyStoreRequest(subject: subject), password);
  });

  group('key stores', () {
    test('a new store holds one private key with the self-signed certificate', () {
      final entries = getKeyStoreEntries(created.keyStore, password);
      expect(entries, hasLength(1));
      expect(entries.single.alias, 'key');
      expect(entries.single.kind, KeyStoreEntryKind.privateKey);
      expect(entries.single.certificates.single.subjectName, 'Тестовий підписувач');
      expect(getCertificate(created.keyStore, password), created.certificate);
    });

    test('the certificate says what was asked', () {
      final details = getCertificateDetails(created.certificate);
      expect(details.subjectName, 'Тестовий підписувач');
      expect(details.subjectAttribute('O'), 'Synthetic Test');
      expect(details.issuer, details.subject);
      expect(details.validTo.difference(details.validFrom).inDays, 365);
      expect(details.validFrom.isUtc, isTrue);
      expect(details.signatureAlgorithm.name, contains('DSTU 4145'));
    });

    test('a wrong password is refused', () {
      expect(() => getKeyStoreEntries(created.keyStore, 'wrong'), throwsA(isA<WrongPasswordException>()));
    });

    test('bytes that are no key store are unreadable', () {
      expect(() => getKeyStoreEntries(Uint8List(16), password), throwsA(isA<UnreadableInputException>()));
    });

    test('a curve degree table Г.1 does not list is an invalid argument', () {
      expect(
        createKeyStore(const KeyStoreRequest(subject: subject, m: 256), password),
        throwsA(isA<InvalidArgumentException>()),
      );
    });

    test('bytes that are no certificate are unreadable', () {
      expect(() => getCertificateDetails(Uint8List(8)), throwsA(isA<UnreadableInputException>()));
    });
  });

  group('sign and verify', () {
    // A CAdES names what it signs "content"; XAdES and the containers name the file.
    for (final (format, level, signedFile) in [
      (SignatureFormat.cades, 'CAdES-B', 'content'),
      (SignatureFormat.xades, 'XAdES-B', 'document.txt'),
      (SignatureFormat.asicS, 'CAdES-B', 'document.txt'),
      (SignatureFormat.asicE, 'XAdES-B', 'document.txt'),
    ]) {
      test('$format at level B verifies against its own certificate, and fails tampered', () async {
        final signature = await sign(created.keyStore, password, [document], options: SigningOptions(format: format));
        final data = format == SignatureFormat.xades ? [document] : const <NamedBytes>[];

        final report = await verify(signature, data: data, trustAnchors: [created.certificate]);
        expect(
          report.isValid,
          isTrue,
          reason: report.signatures.expand((s) => s.checks).map((c) => c.details).join('\n'),
        );
        final summary = report.signatures.firstWhere((summary) => !summary.isContainer);
        expect(summary.level, startsWith(level));
        expect(summary.signer?.subjectName, 'Тестовий підписувач');
        expect(summary.signingTime, isNotNull);
        expect(report.signedFiles, contains(signedFile));

        switch (format) {
          case SignatureFormat.xades:
            final tamperedData = [NamedBytes(document.name, Uint8List.fromList(utf8.encode('Інший документ\n')))];
            final tampered = await verify(signature, data: tamperedData, trustAnchors: [created.certificate]);
            expect(tampered.isValid, isFalse);
            expect(tampered.failureCount, greaterThan(0));
          case SignatureFormat.cades:
            final tampered = await verify(_flipDocumentByte(signature), trustAnchors: [created.certificate]);
            expect(tampered.isValid, isFalse);
            expect(tampered.failureCount, greaterThan(0));
          // The ZIP checksum of the entry gives a changed document away before any signature check.
          case SignatureFormat.asicS || SignatureFormat.asicE:
            expect(
              verify(_flipDocumentByte(signature), trustAnchors: [created.certificate]),
              throwsA(isA<UnreadableInputException>()),
            );
        }
      });
    }

    test('a detached CAdES verifies with its data and not with other data', () async {
      final signature = await sign(created.keyStore, password, [
        document,
      ], options: const SigningOptions(isDetached: true, hash: SignatureHash.gost34311));
      final report = await verify(signature, data: [document], trustAnchors: [created.certificate]);
      expect(report.isValid, isTrue);
      expect(report.signatures.single.packaging, 'detached');
      expect(report.signatures.single.digestAlgorithm?.name, contains('34.311'));

      final other = NamedBytes('document.txt', Uint8List.fromList(utf8.encode('other')));
      expect((await verify(signature, data: [other], trustAnchors: [created.certificate])).isValid, isFalse);
    });

    test('without the trust anchor the path is not trusted', () async {
      final signature = await sign(created.keyStore, password, [document]);
      final report = await verify(signature);
      expect(report.isValid && report.warningCount == 0, isFalse);
    });

    test('a time-stamping service that does not answer is a service failure', () async {
      expect(
        sign(created.keyStore, password, [
          document,
        ], options: const SigningOptions(level: SignatureLevel.t, tsaUrl: 'http://127.0.0.1:9/tsp')),
        throwsA(isA<ServiceFailureException>()),
      );
    });

    test('bytes of no signature format are unreadable', () {
      expect(verify(Uint8List.fromList(utf8.encode('not a signature'))), throwsA(isA<UnreadableInputException>()));
    });
  });
}

// An enveloped CAdES and an ASiC container carry the document as is; one of its bytes changed.
Uint8List _flipDocumentByte(Uint8List signature) {
  final text = utf8.encode('Тестовий документ\n');
  final copy = Uint8List.fromList(signature);
  for (var index = 0; index + text.length <= copy.length; index++) {
    var matches = true;
    for (var offset = 0; offset < text.length && matches; offset++) {
      matches = copy[index + offset] == text[offset];
    }
    if (matches) {
      copy[index] ^= 0x01;
      return copy;
    }
  }
  throw StateError('The signature does not carry the document uncompressed');
}
