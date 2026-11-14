class AppUser {
  final String uid;
  final String fullName;
  final String email;
  final String role; // 'student' | 'staff'

  const AppUser({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.role,
  });

  bool get isStaff => role == 'staff';

  factory AppUser.fromMap(String uid, Map<String, dynamic> d) => AppUser(
        uid: uid,
        fullName: (d['fullName'] as String?) ?? 'Student',
        email: (d['email'] as String?) ?? '',
        role: (d['role'] as String?) ?? 'student',
      );
}
