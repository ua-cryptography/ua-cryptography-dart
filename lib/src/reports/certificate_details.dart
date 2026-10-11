import 'json_fields.dart';
import 'named_algorithm.dart';

/// What a certificate says.
final class CertificateDetails {
  /// The subject, e.g. `CN=Name, O=Organization, C=UA`.
  final String subject;

  /// The issuer.
  final String issuer;

  /// The serial number, upper-case hex without leading zeros.
  final String serial;

  /// The start of the validity period, UTC.
  final DateTime validFrom;

  /// The end of the validity period, UTC.
  final DateTime validTo;

  /// The algorithm the issuer signed the certificate with.
  final NamedAlgorithm signatureAlgorithm;

  /// basicConstraints cA: the certificate of a certification authority.
  final bool isCa;

  /// The OCSP responders of authorityInfoAccess.
  final List<String> ocspUrls;

  /// The caIssuers addresses of authorityInfoAccess.
  final List<String> caIssuerUrls;

  /// The time-stamping services of subjectInfoAccess.
  final List<String> timeStampUrls;

  /// The details as a report gives them.
  const CertificateDetails({
    required this.subject,
    required this.issuer,
    required this.serial,
    required this.validFrom,
    required this.validTo,
    required this.signatureAlgorithm,
    required this.isCa,
    required this.ocspUrls,
    required this.caIssuerUrls,
    required this.timeStampUrls,
  });

  /// Reads the `certificate_details` of a report.
  factory CertificateDetails.fromJson(Map<String, Object?> map) {
    final json = JsonFields(map);
    return CertificateDetails(
      subject: json.string('subject'),
      issuer: json.string('issuer'),
      serial: json.string('serial'),
      validFrom: json.time('valid_from'),
      validTo: json.time('valid_to'),
      signatureAlgorithm: NamedAlgorithm.fromJson(json.object('signature_algorithm')),
      isCa: json.boolean('is_ca'),
      ocspUrls: json.strings('ocsp_urls'),
      caIssuerUrls: json.strings('ca_issuer_urls'),
      timeStampUrls: json.strings('time_stamp_urls'),
    );
  }

  /// The common name of the subject (`CN=`), else the whole subject.
  String get subjectName => _commonName(subject);

  /// The common name of the issuer (`CN=`), else the whole issuer.
  String get issuerName => _commonName(issuer);

  /// The value of the attribute [type] (e.g. `O`, `SERIALNUMBER`) of the subject, or null.
  String? subjectAttribute(String type) => _attribute(subject, type);

  static String _commonName(String name) => _attribute(name, 'CN') ?? name;

  // The attributes of a name as the reports write it: "TYPE=value" separated by ", ". A value with a comma is quoted.
  static String? _attribute(String name, String type) {
    final match = RegExp('(?:^|, )${RegExp.escape(type)}=("(?:[^"\\\\]|\\\\.)*"|[^,]*)').firstMatch(name);
    final value = match?.group(1);
    if (value == null) {
      return null;
    }
    return value.startsWith('"') ? value.substring(1, value.length - 1).replaceAll(r'\"', '"') : value;
  }
}
