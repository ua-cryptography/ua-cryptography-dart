import 'dart:convert';
import 'dart:typed_data';

/// The DER certificates in a certificate file: DER, PEM (one or several) or a PKCS#7 bundle (`.p7b`, DER or PEM).
///
/// Throws a [FormatException] when the file holds no certificate.
List<Uint8List> splitCertificates(Uint8List bytes) {
  final pemBlocks = _pemBlocks(bytes);
  final ders = pemBlocks.isEmpty ? [bytes] : pemBlocks;
  final certificates = [
    for (final der in ders) ..._isPkcs7(der) ? _pkcs7Certificates(der) : [der],
  ];
  if (certificates.isEmpty) {
    throw const FormatException('The file holds no certificate');
  }
  return certificates;
}

final RegExp _pemBlock = RegExp(r'-----BEGIN ([A-Z0-9 ]+)-----([\s\S]*?)-----END \1-----');

List<Uint8List> _pemBlocks(Uint8List bytes) {
  final text = latin1.decode(bytes, allowInvalid: true);
  return [for (final match in _pemBlock.allMatches(text)) base64.decode(match.group(2)!.replaceAll(RegExp(r'\s'), ''))];
}

// ContentInfo ::= SEQUENCE { contentType OID 1.2.840.113549.1.7.2 (signedData), content [0] EXPLICIT SignedData }
const List<int> _signedDataOid = [0x06, 0x09, 0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x07, 0x02];

bool _isPkcs7(Uint8List der) {
  if (der.isEmpty || der[0] != 0x30) {
    return false;
  }
  final contentStart = _DerElement.read(der, 0).contentStart;
  if (contentStart + _signedDataOid.length > der.length) {
    return false;
  }
  for (var index = 0; index < _signedDataOid.length; index++) {
    if (der[contentStart + index] != _signedDataOid[index]) {
      return false;
    }
  }
  return true;
}

// SignedData ::= SEQUENCE { version, digestAlgorithms SET, encapContentInfo SEQUENCE,
//   certificates [0] IMPLICIT SET OF Certificate OPTIONAL, ... }
List<Uint8List> _pkcs7Certificates(Uint8List der) {
  final contentInfo = _DerElement.read(der, 0);
  final contentType = _DerElement.read(der, contentInfo.contentStart);
  final explicitContent = _DerElement.read(der, contentType.end);
  final signedData = _DerElement.read(der, explicitContent.contentStart);
  var offset = signedData.contentStart;
  for (var skipped = 0; skipped < 3; skipped++) {
    offset = _DerElement.read(der, offset).end;
  }
  if (offset >= signedData.end || der[offset] != 0xA0) {
    return const [];
  }
  final certificateSet = _DerElement.read(der, offset);
  final certificates = <Uint8List>[];
  for (var position = certificateSet.contentStart; position < certificateSet.end;) {
    final certificate = _DerElement.read(der, position);
    certificates.add(Uint8List.sublistView(der, position, certificate.end));
    position = certificate.end;
  }
  return certificates;
}

/// One tag-length-value of DER: where its content starts and where it ends.
final class _DerElement {
  final int contentStart;
  final int end;

  const _DerElement(this.contentStart, this.end);

  static _DerElement read(Uint8List der, int offset) {
    if (offset + 2 > der.length) {
      throw const FormatException('Truncated DER');
    }
    final lengthByte = der[offset + 1];
    var position = offset + 2;
    var length = lengthByte;
    if (lengthByte & 0x80 != 0) {
      final lengthBytes = lengthByte & 0x7F;
      if (lengthBytes == 0 || lengthBytes > 4 || position + lengthBytes > der.length) {
        throw const FormatException('Unsupported DER length');
      }
      length = 0;
      for (var index = 0; index < lengthBytes; index++) {
        length = (length << 8) | der[position++];
      }
    }
    if (position + length > der.length) {
      throw const FormatException('Truncated DER');
    }
    return _DerElement(position, position + length);
  }
}
