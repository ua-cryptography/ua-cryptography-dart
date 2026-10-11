import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:ua_cryptography/src/bindings/native_release.dart';
import 'package:ua_cryptography/ua_cryptography.dart';

import 'support/hex.dart';

// The examples of DSTU 7564:2014 (as in BouncyCastle's DSTU7564Test), from ua-cryptography-dstu7564/tests/kupyna.rs.
// The message is the n bytes 00 01 02 … (n − 1), or FF.
const List<(int, Object, String)> standardExamples = [
  (256, 64, '08F4EE6F1BE6903B324C4E27990CB24EF69DD58DBE84813EE0A52F6631239875'),
  (256, 128, '0A9474E645A7D25E255E9E89FFF42EC7EB31349007059284F0B182E452BDA882'),
  (256, 256, 'D305A32B963D149DC765F68594505D4077024F836C1BF03806E1624CE176C08F'),
  (256, 'FF', 'EA7677CA4526555680441C117982EA14059EA6D0D7124D6ECDB3DEEC49E890F4'),
  (256, 95, '1075C8B0CB910F116BDA5FA1F19C29CF8ECC75CAFF7208BA2994B68FC56E8D16'),
  (256, 0, 'CD5101D1CCDF0D1D1F4ADA56E888CD724CA1A0838A3521E7131D4FB78D0F5EB6'),
  (384, 95, 'D9021692D84E5175735654846BA751E6D0ED0FAC36DFBC0841287DCB0B5584C75016C3DECC2A6E47C50B2F3811E351B8'),
  (
    512,
    64,
    '3813E2109118CDFB5A6D5E72F7208DCCC80A2DFB3AFDFB02F46992B5EDBE536B'
        '3560DD1D7E29C6F53978AF58B444E37BA685C0DD910533BA5D78EFFFC13DE62A',
  ),
  (
    512,
    'FF',
    '871B18CF754B72740307A97B449ABEB32B64444CC0D5A4D65830AE5456837A72'
        'D8458F12C8F06C98C616ABE11897F86263B5CB77C420FB375374BEC52B6D0292',
  ),
  (
    512,
    0,
    '656B2F4CD71462388B64A37043EA55DBE445D452AECD46C3298343314EF04019'
        'BCFA3F04265A9857F91BE91FCE197096187CEDA78C9C1C021C294A0689198538',
  ),
];

void main() {
  test('the loaded native library is the pinned release', () {
    expect(getVersion(), nativeLibraryVersion);
  });

  for (final (hashBits, message, expected) in standardExamples) {
    test('Kupyna-$hashBits of ${message is int ? '$message sequential bytes' : message}', () {
      final data = switch (message) {
        final int length => Uint8List.fromList(List.generate(length, (index) => index)),
        final String hex => fromHex(hex),
        _ => throw ArgumentError.value(message),
      };
      expect(toHex(dstu7564CalculateHash(data, hashBits)), expected);
    });
  }

  test('a hash size the standard does not define is an invalid argument with the library message', () {
    expect(
      () => dstu7564CalculateHash(Uint8List(0), 128),
      throwsA(isA<InvalidArgumentException>().having((refusal) => refusal.message, 'message', isNotEmpty)),
    );
  });
}
