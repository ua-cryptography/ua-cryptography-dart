import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/trust/trust_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final trustStore = await TrustStore.load();
  runApp(UaSignatureApp(trustStore: trustStore));
}
