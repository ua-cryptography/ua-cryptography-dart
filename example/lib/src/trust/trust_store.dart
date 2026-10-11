import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ua_cryptography/ua_cryptography.dart';

import 'certificate_files.dart';

/// What a certificate is trusted for.
enum TrustRole {
  /// A path must end at one of these.
  root,

  /// Completes paths: CAs, time-stamping and OCSP services.
  intermediate;

  /// The folder of `assets/certificates` the bundled ones of this role are in.
  String get folder => switch (this) {
    root => 'roots',
    intermediate => 'intermediates',
  };
}

/// A certificate verification relies on.
final class TrustedCertificate {
  final Uint8List der;
  final CertificateDetails details;
  final TrustRole role;
  final bool isBuiltIn;

  /// The asset file it came from, or "added".
  final String source;

  const TrustedCertificate({
    required this.der,
    required this.details,
    required this.role,
    required this.isBuiltIn,
    required this.source,
  });
}

/// The certificates verification relies on: the public roots and intermediates bundled in `assets/certificates`, and
/// those the user added, kept in shared preferences as `<role>:<base64 DER>` — public certificates, nothing secret.
class TrustStore extends ChangeNotifier {
  static const String _storageKey = 'ua_signature.certificates';
  static const String _assetRoot = 'assets/certificates/';

  final List<TrustedCertificate> _entries = [];

  TrustStore._();

  /// The bundled certificates and the stored ones.
  static Future<TrustStore> load() async {
    final store = TrustStore._();
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    // Roots first: the PrivatBank bundle among the intermediates carries some of the roots too.
    for (final role in TrustRole.values) {
      final assets = manifest.listAssets().where((asset) => asset.startsWith('$_assetRoot${role.folder}/')).toList()
        ..sort();
      for (final asset in assets) {
        final bytes = (await rootBundle.load(asset)).buffer.asUint8List();
        for (final der in splitCertificates(bytes)) {
          store._push(der, role, isBuiltIn: true, source: asset.split('/').last);
        }
      }
    }
    final preferences = await SharedPreferences.getInstance();
    for (final stored in preferences.getStringList(_storageKey) ?? const <String>[]) {
      final [roleName, encoded] = stored.split(':');
      try {
        store._push(base64.decode(encoded), TrustRole.values.byName(roleName), isBuiltIn: false, source: 'added');
      } on Object {
        // A damaged stored entry is dropped at the next save.
      }
    }
    return store;
  }

  /// Every certificate, the bundled ones first.
  List<TrustedCertificate> get entries => List.unmodifiable(_entries);

  /// The trusted roots, DER.
  List<Uint8List> get trustAnchors => [
    for (final entry in _entries)
      if (entry.role == TrustRole.root) entry.der,
  ];

  /// The intermediate certificates, DER.
  List<Uint8List> get certificates => [
    for (final entry in _entries)
      if (entry.role == TrustRole.intermediate) entry.der,
  ];

  /// Adds the certificates of a file with [role]; returns how many were new. A known certificate added as a root
  /// becomes one.
  Future<int> addFile(Uint8List bytes, TrustRole role) async {
    var added = 0;
    for (final der in splitCertificates(bytes)) {
      final existing = _entries.indexWhere((entry) => listEquals(entry.der, der));
      if (existing < 0) {
        _push(der, role, isBuiltIn: false, source: 'added');
        added++;
      } else if (role == TrustRole.root && _entries[existing].role != TrustRole.root) {
        final entry = _entries[existing];
        _entries[existing] = TrustedCertificate(
          der: entry.der,
          details: entry.details,
          role: TrustRole.root,
          isBuiltIn: false,
          source: 'added',
        );
        added++;
      }
    }
    if (added > 0) {
      await _save();
    }
    return added;
  }

  /// Removes an added certificate; bundled ones stay.
  Future<void> remove(TrustedCertificate certificate) async {
    _entries.removeWhere((entry) => !entry.isBuiltIn && identical(entry, certificate));
    await _save();
  }

  void _push(Uint8List der, TrustRole role, {required bool isBuiltIn, required String source}) {
    if (_entries.any((entry) => listEquals(entry.der, der))) {
      return;
    }
    final details = getCertificateDetails(der);
    _entries.add(TrustedCertificate(der: der, details: details, role: role, isBuiltIn: isBuiltIn, source: source));
  }

  Future<void> _save() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(_storageKey, [
      for (final entry in _entries)
        if (!entry.isBuiltIn) '${entry.role.name}:${base64.encode(entry.der)}',
    ]);
    notifyListeners();
  }
}
