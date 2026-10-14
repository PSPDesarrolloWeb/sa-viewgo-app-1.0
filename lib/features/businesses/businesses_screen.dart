import 'package:flutter/material.dart';
import 'package:saviewgo/core/theme/theme_config.dart';
import 'package:saviewgo/shared/widgets/pending_content.dart';
import 'package:saviewgo/shared/widgets/shell_app_bar.dart';

class BusinessesScreen extends StatelessWidget {
  const BusinessesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConfig.getBackgroundColor(context),
      appBar: const ShellAppBar(title: 'Negocios'),
      body: const PendingContent(
        icon: Icons.storefront_outlined,
        message: 'Aquí irá la lista paginada de negocios.',
      ),
    );
  }
}