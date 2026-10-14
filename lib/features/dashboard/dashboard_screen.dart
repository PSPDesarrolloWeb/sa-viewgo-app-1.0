import 'package:flutter/material.dart';
import 'package:saviewgo/core/theme/theme_config.dart';
import 'package:saviewgo/shared/widgets/pending_content.dart';
import 'package:saviewgo/shared/widgets/shell_app_bar.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConfig.getBackgroundColor(context),
      appBar: const ShellAppBar(title: 'Resumen'),
      body: const PendingContent(
        icon: Icons.insights_rounded,
        message: 'Aquí irán los KPIs y lo que requiere atención.',
      ),
    );
  }
}