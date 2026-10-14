import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saviewgo/features/auth/app_lock_controller.dart';
import 'package:saviewgo/features/auth/auth_repository.dart';


class LoginState {
  const LoginState({this.loading = false, this.error, this.notice});
 
  final bool loading;
  final String? error;
 
  /// Mensaje informativo, por ejemplo tras pedir el enlace de contraseña.
  final String? notice;
}
 
final loginControllerProvider =
    NotifierProvider.autoDispose<LoginController, LoginState>(
  LoginController.new,
);
 
class LoginController extends Notifier<LoginState> {
  @override
  LoginState build() => const LoginState();
 
  /// Solo inicia sesión. Rol, ciudad y registro de la sesión los valida
  /// el splash, que es a donde se navega después.
  Future<bool> submit({required String email, required String password}) async {
    state = const LoginState(loading: true);
    try {
      await ref.read(authRepositoryProvider).signIn(email, password);
      ref.read(appLockProvider.notifier).markLoggedIn();
      return true;
    } catch (error) {
      if (ref.mounted) state = LoginState(error: authErrorMessage(error));
      return false;
    }
  }
 
  Future<void> requestPasswordReset(String email) async {
    state = const LoginState(loading: true);
    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(email);
    } on FirebaseAuthException catch (error) {
      if (error.code == 'invalid-email') {
        if (ref.mounted) {
          state = const LoginState(error: 'Revisa el formato del correo.');
        }
        return;
      }
    } catch (_) {}
    // Mismo mensaje exista o no la cuenta, para no revelar qué correos
    // están registrados.
    if (ref.mounted) {
      state = const LoginState(
        notice:
            'Si el correo está registrado, te llegará un enlace para restablecer tu contraseña.',
      );
    }
  }
}
 