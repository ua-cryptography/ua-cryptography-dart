## 0.1.0

The first release, over the native library of [ua-cryptography-rust](https://github.com/ua-cryptography/ua-cryptography-rust)
0.1.6.

- Signing as CAdES, XAdES, ASiC-S and ASiC-E at levels B, T and LT (`sign`), and verification of any of them with a
  report of every check (`verify`).
- JKS key stores: a new one with a DSTU 4145 key and its self-signed certificate (`createKeyStore`), its entries
  (`getKeyStoreEntries`) and the certificate of its key (`getCertificate`); what a certificate says
  (`getCertificateDetails`).
- DSTU 7564 (Kupyna) of 256, 384 and 512 bits (`dstu7564CalculateHash`).
- A build hook that downloads the native library of the target from the GitHub release, checked against the pinned
  SHA-256, or copies it from the `local_library_dir` user-define.
- Android, iOS, macOS, Linux and Windows.

## 0.1.0-dev

A preview, published to set up the package on pub.dev.
