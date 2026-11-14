import 'package:campus_incident_app/core/constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('assigns student role to ALU student addresses', () {
    expect(roleForEmail('sam@alustudent.com'), 'student');
  });

  test('assigns staff role to ALU education addresses case-insensitively', () {
    expect(roleForEmail('Sam@ALUEDUCATION.COM'), 'staff');
  });

  test('rejects domains that only contain an allowed domain as a suffix', () {
    expect(roleForEmail('sam@alueducation.com.example.org'), isNull);
    expect(isAllowedEmail('sam@alustudent.com.example.org'), isFalse);
  });
}
