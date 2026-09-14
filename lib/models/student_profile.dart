class StudentProfile {
  const StudentProfile({
    required this.uid,
    required this.email,
    this.displayName = '',
    this.selectedElectiveKeys = const {},
  });

  final String uid;
  final String email;
  final String displayName;
  final Set<String> selectedElectiveKeys;

  StudentProfile copyWith({Set<String>? selectedElectiveKeys}) {
    return StudentProfile(
      uid: uid,
      email: email,
      displayName: displayName,
      selectedElectiveKeys: selectedElectiveKeys ?? this.selectedElectiveKeys,
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'selectedElectiveKeys': selectedElectiveKeys.toList(),
      };

  factory StudentProfile.fromMap(Map<String, dynamic> map) {
    final keys = map['selectedElectiveKeys'] as List<dynamic>? ?? const [];
    return StudentProfile(
      uid: map['uid'] as String? ?? '',
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      selectedElectiveKeys: keys.map((e) => e.toString()).toSet(),
    );
  }
}
