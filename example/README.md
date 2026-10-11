# ua_cryptography example

Verifies and signs Ukrainian qualified electronic signatures with the `ua_cryptography` package, on Android, iOS,
macOS, Linux and Windows. The three tabs follow the single-page app of
[ua-cryptography-typescript](https://github.com/ua-cryptography/ua-cryptography-typescript):

- **Verify** — choose a signed file (`.sig` / `.p7s` CAdES, `.asice` / `.asics` ASiC, `.xml` XAdES), and for a
  detached signature the signed files with it. The report shows the signer, the signing and time-stamp times, every
  check and the signed digests. The online check (off by default) asks the OCSP servers the certificates name.
- **Sign** — open a `.jks` key store with its password (or create a synthetic test key), choose a document, a format
  (CAdES, XAdES, ASiC-S, ASiC-E), a level (B offline; T and LT when the certificate names a time-stamping service) and a
  hash. The signature is saved and verified on the spot.
- **Certificates** — the trusted roots (ЦЗО, НБУ) and intermediates («Дія», PrivatBank and its bundle) built in from
  `assets/certificates`, all public; more can be added (DER, PEM or `.p7b`) and are kept on the device.

The native library is downloaded by the package's build hook from the GitHub release it pins; nothing to install.

```sh
flutter run                                  # on a connected device, a simulator or the desktop
flutter test integration_test -d <device>    # the library flows on that device, without the UI
```

Minimum versions: Android API 21, iOS 15, macOS 12 (what Xcode 27 builds for), glibc 2.35, Windows 10.
