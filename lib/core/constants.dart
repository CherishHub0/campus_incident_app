const studentEmailDomain = 'alustudent.com';
const staffEmailDomain = 'alueducation.com';
const allowedEmailDomains = [studentEmailDomain, staffEmailDomain];

const campusLocations = [
  'Student Residence',
  'Block A',
  'Block B',
  'Block C',
  'Cafeteria',
  'Library',
  'Sports Field',
  'Parking Lot',
  'Admin Block',
  'Other',
];

bool isAllowedEmail(String email) {
  return roleForEmail(email) != null;
}

String? roleForEmail(String email) {
  final normalized = email.trim().toLowerCase();
  if (normalized.endsWith('@$studentEmailDomain')) return 'student';
  if (normalized.endsWith('@$staffEmailDomain')) return 'staff';
  return null;
}
