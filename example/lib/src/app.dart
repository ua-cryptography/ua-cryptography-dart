import 'package:flutter/material.dart';

import 'sign/sign_page.dart';
import 'trust/certificates_page.dart';
import 'trust/trust_store.dart';
import 'verify/verify_page.dart';

/// Verify and sign Ukrainian e-signatures: the three tabs of the TypeScript page, over ua_cryptography.
class UaSignatureApp extends StatelessWidget {
  final TrustStore trustStore;

  const UaSignatureApp({super.key, required this.trustStore});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ukrainian e-signature',
      theme: ThemeData(colorSchemeSeed: const Color(0xFF1F5FBF), useMaterial3: true),
      home: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ukrainian e-signature'),
                Text('DSTU 4145 · CAdES · XAdES · ASiC', style: TextStyle(fontSize: 12)),
              ],
            ),
            bottom: const TabBar(
              tabs: [
                Tab(text: 'Verify'),
                Tab(text: 'Sign'),
                Tab(text: 'Certificates'),
              ],
            ),
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: TabBarView(
                children: [
                  VerifyPage(trustStore: trustStore),
                  SignPage(trustStore: trustStore),
                  CertificatesPage(trustStore: trustStore),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
