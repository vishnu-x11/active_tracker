class AuthUser {
  const AuthUser({required this.uid, this.email, this.phoneNumber, this.displayName});

  final String uid;
  final String? email;
  final String? phoneNumber;
  final String? displayName;

  @override
  bool operator ==(Object other) =>
      other is AuthUser &&
      other.uid == uid &&
      other.email == email &&
      other.phoneNumber == phoneNumber &&
      other.displayName == displayName;

  @override
  int get hashCode => Object.hash(uid, email, phoneNumber, displayName);
}
