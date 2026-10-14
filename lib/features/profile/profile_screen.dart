import 'package:flutter/material.dart';
import 'package:saviewgo/core/theme/theme_config.dart';
import 'package:saviewgo/shared/widgets/pending_content.dart';
import 'package:saviewgo/shared/widgets/shell_app_bar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConfig.getBackgroundColor(context),
      appBar: const ShellAppBar(title: 'Perfil'),
      body: const PendingContent(
        icon: Icons.person_outline_rounded,
        message: 'Aquí irán tu cuenta, el bloqueo y el cierre de sesión.',
      ),
    );
  }
}