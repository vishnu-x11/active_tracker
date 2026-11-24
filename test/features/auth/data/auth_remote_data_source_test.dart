import 'package:active_tracker/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';

class _User extends Fake implements User {
  String? name;
  bool failName = false;

  @override
  Future<void> updateDisplayName(String? displayName) async {
    if (failName) throw FirebaseAuthException(code: 'network-request-failed');
    name = displayName;
  }
}

class _Credential extends Fake implements UserCredential {
  _Credential(this.user);

  @override
  final User user;
}

class _Auth extends Fake implements FirebaseAuth {
  final user = _User();
  var created = false;
  var signedOut = false;

  @override
  Future<UserCredential> createUserWithEmailAndPassword({required String email, required String password}) async {
    created = true;
    return _Credential(user);
  }

  @override
  Future<void> signOut() async => signedOut = true;
}

class _Google extends Fake implements GoogleSignIn {}

void main() {
  test('creating an account never signs the app in, so the user goes to the login screen', () async {
    final app = _Auth(), signUp = _Auth();
    await AuthRemoteDataSourceImpl(
      app,
      _Google(),
      signUpAuth: () async => signUp,
    ).createAccount(name: 'Vishnu', email: 'v@x.com', password: 'secret12');
    expect(app.created, isFalse);
    expect(app.signedOut, isFalse);
    expect(signUp.created, isTrue);
    expect(signUp.user.name, 'Vishnu');
    expect(signUp.signedOut, isTrue);
  });

  test('the sign-up session is closed even when saving the name fails', () async {
    final signUp = _Auth()..user.failName = true;
    final source = AuthRemoteDataSourceImpl(_Auth(), _Google(), signUpAuth: () async => signUp);
    await expectLater(
      source.createAccount(name: 'Vishnu', email: 'v@x.com', password: 'secret12'),
      throwsA(isA<FirebaseAuthException>()),
    );
    expect(signUp.signedOut, isTrue);
  });
}
