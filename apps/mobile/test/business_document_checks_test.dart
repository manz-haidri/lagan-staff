import 'package:flutter_test/flutter_test.dart';
import 'package:lagan_staff/features/owner/models/document_evidence.dart';

void main() {
  test('checks business name, legibility, and certificate type', () {
    DocumentIssue? check(String type, String text) =>
        checkDocumentEvidence(type, text, 'Shahi Lawn');
    expect(check('visiting_card', ''), DocumentIssue.unreadable);
    expect(
      check('business_photo', 'Some other place'),
      DocumentIssue.businessName,
    );
    expect(check('visiting_card', 'SHAHI\nLAWN • Banquets'), isNull);
    expect(check('gst_certificate', 'Shahi Lawn GST'), DocumentIssue.gst);
    expect(
      check('business_registration', 'Shahi Lawn Banquets'),
      DocumentIssue.registration,
    );
    expect(
      check('business_registration', 'Registration certificate for Shahi Lawn'),
      isNull,
    );
  });
}
