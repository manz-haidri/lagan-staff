enum DocumentIssue { unreadable, businessName, registration, gst }

DocumentIssue? checkDocumentEvidence(
  String type,
  String text,
  String businessName,
) {
  String normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^\p{L}\p{M}\p{N}]+', unicode: true), ' ')
      .trim();
  final words = normalize(text);
  if (words.length < 6) return DocumentIssue.unreadable;
  final name = normalize(businessName);
  if (name.isEmpty || !' $words '.contains(' $name ')) {
    return DocumentIssue.businessName;
  }
  if (type == 'gst_certificate') {
    final gstin = RegExp(r'\b[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]\b');
    if (!gstin.hasMatch(text.toUpperCase()) ||
        !RegExp(
          r'GST|goods and services tax|माल और सेवा कर',
          caseSensitive: false,
        ).hasMatch(text)) {
      return DocumentIssue.gst;
    }
  }
  if (type == 'business_registration' &&
      !RegExp(
        r'registration|incorporation|udyam|licen[cs]e|पंजीकरण|पंजीयन|अनुज्ञप्ति',
        caseSensitive: false,
      ).hasMatch(text)) {
    return DocumentIssue.registration;
  }
  return null;
}
