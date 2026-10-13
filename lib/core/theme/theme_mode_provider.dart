import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saviewgo/core/security/secure_storage.dart';

final themeModeProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);

/// Sigue al sistema hasta que el usuario elige un tema; la elección
/// se guarda en el dispositivo.
class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _restore();
    return ThemeMode.system;
  }

  Future<void> _restore() async {
    final saved =
        await ref.read(secureStorageProvider).read(key: StorageKeys.themeMode);
    for (final mode in ThemeMode.values) {
      if (mode.name == saved) state = mode;
    }
  }

  Future<void> toggle(Brightness current) async {
    state = current == Brightness.dark ? ThemeMode.light : ThemeMode.dark;
    await ref
        .read(secureStorageProvider)
        .write(key: StorageKeys.themeMode, value: state.name);
  }
}