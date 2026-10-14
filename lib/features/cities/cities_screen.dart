import 'package:flutter/material.dart';
import 'package:saviewgo/core/theme/theme_config.dart';
import 'package:saviewgo/shared/widgets/pending_content.dart';
import 'package:saviewgo/shared/widgets/shell_app_bar.dart';

class CitiesScreen extends StatelessWidget {
  const CitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConfig.getBackgroundColor(context),
      appBar: const ShellAppBar(title: 'Ciudades'),
      body: const PendingContent(
        icon: Icons.location_on_outlined,
        message: 'Aquí irá el catálogo de ciudades.',
      ),
    );
  }
}