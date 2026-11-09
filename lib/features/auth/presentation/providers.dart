import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/providers/core_providers.dart';
import '../data/data_sources/auth_remote_data_source.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/use_cases/resend_phone_code.dart';
import '../domain/use_cases/send_password_reset.dart';
import '../domain/use_cases/send_phone_code.dart';
import '../domain/use_cases/sign_in_with_email.dart';
import '../domain/use_cases/sign_in_with_google.dart';
import '../domain/use_cases/sign_out.dart';
import '../domain/use_cases/sign_up_with_email.dart';
import '../domain/use_cases/verify_phone_code.dart';

final googleSignInProvider = Provider<GoogleSignIn>(
  (ref) => GoogleSignIn(serverClientId: AuthRemoteDataSourceImpl.googleServerClientId),
);

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => AuthRemoteDataSourceImpl(ref.watch(firebaseAuthProvider), ref.watch(googleSignInProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(ref.watch(authRemoteDataSourceProvider)),
);

final signInWithEmailProvider = Provider((ref) => SignInWithEmail(ref.watch(authRepositoryProvider)));
final signUpWithEmailProvider = Provider((ref) => SignUpWithEmail(ref.watch(authRepositoryProvider)));
final sendPasswordResetProvider = Provider((ref) => SendPasswordReset(ref.watch(authRepositoryProvider)));
final signInWithGoogleProvider = Provider((ref) => SignInWithGoogle(ref.watch(authRepositoryProvider)));
final sendPhoneCodeProvider = Provider((ref) => SendPhoneCode(ref.watch(authRepositoryProvider)));
final resendPhoneCodeProvider = Provider((ref) => ResendPhoneCode(ref.watch(authRepositoryProvider)));
final verifyPhoneCodeProvider = Provider((ref) => VerifyPhoneCode(ref.watch(authRepositoryProvider)));
final signOutProvider = Provider((ref) => SignOut(ref.watch(authRepositoryProvider)));
