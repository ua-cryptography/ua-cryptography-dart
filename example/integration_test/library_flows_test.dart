// The flows of the app without its UI, on a device, simulator or desktop: this is what proves the native library is
// bundled, loads and works on each platform. Synthetic keys only, generated per run.
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ua_cryptography/ua_cryptography.dart';
import 'package:ua_cryptography_example/src/app.dart';
import 'package:ua_cryptography_example/src/trust/trust_store.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  test('the bundled native library loads and computes Kupyna-256', () {
    expect(getVersion(), isNotEmpty);
    // DSTU 7564:2014, the example of the empty message.
    final hash = dstu7564CalculateHash(Uint8List(0), 256);
    expect(
      hash.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join().toUpperCase(),
      'CD5101D1CCDF0D1D1F4ADA56E888CD724CA1A0838A3521E7131D4FB78D0F5EB6',
    );
  });

  test('the bundled certificates load, the PrivatBank bundle split into its certificates', () async {
    final store = await TrustStore.load();
    final roots = store.entries.where((entry) => entry.role == TrustRole.root);
    final intermediates = store.entries.where((entry) => entry.role == TrustRole.intermediate);
    expect(roots, hasLength(5));
    expect(roots.every((entry) => entry.details.isCa), isTrue);
    expect(intermediates.length, greaterThan(2));
    expect(intermediates.where((entry) => entry.source.endsWith('.p7b')), isNotEmpty);
  });

  group('a synthetic key', () {
    late CreatedKeyStore created;
    const password = 'synthetic-password';
    final document = NamedBytes('document.txt', Uint8List.fromList(utf8.encode('Тестовий документ\n')));

    setUpAll(() async {
      created = await createKeyStore(const KeyStoreRequest(subject: 'CN=Тестовий підписувач,C=UA'), password);
    });

    for (final format in SignatureFormat.values) {
      test('signs as $format and the signature verifies', () async {
        final signature = await sign(created.keyStore, password, [document], options: SigningOptions(format: format));
        final report = await verify(
          signature,
          data: format == SignatureFormat.xades ? [document] : const [],
          trustAnchors: [created.certificate],
        );
        expect(report.isValid, isTrue);
      });
    }

    test('a wrong password is refused', () {
      expect(() => getKeyStoreEntries(created.keyStore, 'wrong'), throwsA(isA<WrongPasswordException>()));
    });
  });

  testWidgets('the app starts with its three tabs', (tester) async {
    await tester.pumpWidget(UaSignatureApp(trustStore: await TrustStore.load()));
    await tester.pumpAndSettle();
    expect(find.text('Verify'), findsOneWidget);
    expect(find.text('Sign'), findsOneWidget);
    expect(find.text('Certificates'), findsOneWidget);

    await tester.tap(find.text('Certificates'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Trusted roots (5)'), findsOneWidget);
  });
}
