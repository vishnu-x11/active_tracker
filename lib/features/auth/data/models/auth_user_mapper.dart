import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/auth_user.dart';

extension FirebaseUserToEntity on User {
  AuthUser toEntity() => AuthUser(uid: uid, email: email, phoneNumber: phoneNumber, displayName: displayName);
}
