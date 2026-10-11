import 'dart:typed_data';

/// A file: its name, as a XAdES reference or an ASiC entry names it, and its content.
final class NamedBytes {
  /// The file name, e.g. `contract.pdf`.
  final String name;

  /// The content.
  final Uint8List content;

  /// A file named [name] holding [content].
  const NamedBytes(this.name, this.content);
}
