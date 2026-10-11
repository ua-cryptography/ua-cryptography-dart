import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:ua_cryptography/ua_cryptography.dart';

/// Files the user picks, read whole; empty when the picker is cancelled.
Future<List<NamedBytes>> pickFiles({List<String>? extensions}) async {
  final picked = await FilePicker.pickFiles(
    type: extensions == null ? FileType.any : FileType.custom,
    allowedExtensions: extensions,
  );
  return [for (final file in picked) NamedBytes(file.name, await file.readAsBytes())];
}

/// A file the user picks, or null when cancelled.
Future<NamedBytes?> pickFile({List<String>? extensions}) async {
  final picked = await FilePicker.pickFile(
    type: extensions == null ? FileType.any : FileType.custom,
    allowedExtensions: extensions,
  );
  return picked == null ? null : NamedBytes(picked.name, await picked.readAsBytes());
}

/// Offers [bytes] for saving as [fileName]; the saved location, or null when cancelled.
Future<Uri?> saveFile(String fileName, Uint8List bytes) => FilePicker.saveFile(fileName: fileName, bytes: bytes);
