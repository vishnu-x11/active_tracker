import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';

abstract interface class AuthRemoteDataSource {
  Future<User> signInWithEmail(String email, String password);
  Future<void> createAccount({required String name, required String email, required String password});
  Future<void> sendPasswordReset(String email);

  Future<User?> signInWithGoogle();
  Future<void> signOut();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._auth, this._google, {Future<FirebaseAuth> Function()? signUpAuth})
    : _signUpAuth = signUpAuth ?? _separateAuth;

  final FirebaseAuth _auth;
  final GoogleSignIn _google;
  final Future<FirebaseAuth> Function() _signUpAuth;

  static const googleServerClientId = '773988908810-g9edgsr32bj76ncpc545e0r29p54mfu5.apps.googleusercontent.com';
  static const signUpAppName = 'sign_up';

  static Future<FirebaseAuth> _separateAuth() async {
    final app =
        Firebase.apps.where((a) => a.name == signUpAppName).firstOrNull ??
        await Firebase.initializeApp(name: signUpAppName, options: Firebase.app().options);
    return FirebaseAuth.instanceFor(app: app);
  }

  User _require(UserCredential c) => c.user ?? (throw StateError('Firebase returned no user'));

  @override
  Future<User> signInWithEmail(String email, String password) async =>
      _require(await _auth.signInWithEmailAndPassword(email: email, password: password));

  @override
  Future<void> createAccount({required String name, required String email, required String password}) async {
    final auth = await _signUpAuth();
    final user = _require(await auth.createUserWithEmailAndPassword(email: email, password: password));
    try {
      await user.updateDisplayName(name);
    } finally {
      await auth.signOut();
    }
  }

  @override
  Future<void> sendPasswordReset(String email) => _auth.sendPasswordResetEmail(email: email);

  @override
  Future<User?> signInWithGoogle() async {
    final account = await _google.signIn();
    if (account == null) return null;
    final tokens = await account.authentication;
    final credential = GoogleAuthProvider.credential(accessToken: tokens.accessToken, idToken: tokens.idToken);
    return _require(await _auth.signInWithCredential(credential));
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    await _google.signOut();
  }
}
