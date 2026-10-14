import 'package:flutter/material.dart';
import 'package:saviewgo/core/theme/theme_config.dart';
import 'package:saviewgo/shared/widgets/pending_content.dart';
import 'package:saviewgo/shared/widgets/shell_app_bar.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConfig.getBackgroundColor(context),
      appBar: const ShellAppBar(title: 'Alertas'),
      body: const PendingContent(
        icon: Icons.notifications_none_rounded,
        message: 'Aquí irá la bandeja de alertas.',
      ),
    );
  }
}