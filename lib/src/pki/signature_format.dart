/// The format of a signature.
enum SignatureFormat {
  /// CMS SignedData (`.p7s`, PrivatBank's `.sig`), enveloped or detached; signs one file.
  cades,

  /// A detached XML signature with one reference per file (`.xml`).
  xades,

  /// A ZIP container with the file and a detached CAdES (`.asics`); signs one file.
  asicS,

  /// A ZIP container with the files and a XAdES signature (`.asice`), as «Дія.Підпис» makes it.
  asicE,
}
