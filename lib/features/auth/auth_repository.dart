import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saviewgo/core/firebase/firebase_init.dart';
import 'package:saviewgo/features/auth/app_lock_controller.dart';
import 'package:saviewgo/features/cities/cities_provider.dart';

final authRepositoryProvider = Provider<AuthRepository>(AuthRepository.new);

class AuthRepository {
  AuthRepository(this._ref);

  final Ref _ref;

  FirebaseAuth get _auth => FirebaseAuth.instance;

  Future<void> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email.trim(), password: password);

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  /// Cierra la sesión y borra del dispositivo lo que quedó en caché.
  Future<void> signOut() async {
    final lock = _ref.read(appLockProvider.notifier);
    await lock.disable();
    lock.lock();

    await _auth.signOut();
    _ref.invalidate(citiesProvider);

    await FirebaseFirestore.instance.terminate();
    await FirebaseFirestore.instance.clearPersistence();
    FirebaseFirestore.instance.settings = firestoreSettings;
  }
}

/// Mensaje para el usuario a partir de un error de Firebase Auth.
String authErrorMessage(Object error) {
  if (error is! FirebaseAuthException) {
    return 'No se pudo iniciar sesión. Intenta de nuevo.';
  }
  return switch (error.code) {
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' =>
      'Correo o contraseña incorrectos.',
    'invalid-email' => 'Revisa el formato del correo.',
    'user-disabled' => 'Esta cuenta está deshabilitada.',
    'too-many-requests' =>
      'Demasiados intentos. Espera unos minutos e intenta de nuevo.',
    'network-request-failed' => 'Sin conexión. Revisa tu red.',
    _ => 'No se pudo iniciar sesión. Intenta de nuevo.',
  };
}