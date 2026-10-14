import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:saviewgo/core/theme/theme_config.dart';
import 'package:saviewgo/shared/utils/date_labels.dart';

/// Saludo con el nombre del usuario, su rol, la ciudad en alcance y la
/// fecha.
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.isGlobalRole,
    required this.cityName,
  });

  final bool isGlobalRole;

  /// Ciudad en alcance; null = todas.
  final String? cityName;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final firstName =
        FirebaseAuth.instance.currentUser?.displayName
            ?.trim()
            .split(' ').first ?? '';
    final greeting = firstName.isEmpty
        ? greetingFor(now)
        : '${greetingFor(now)}, $firstName';

    final role = isGlobalRole ? 'Superadmin global' : 'Superadmin de ciudad';
    final scope = cityName ?? (isGlobalRole ? 'Todas las ciudades' : null);
    final line = [role, ?scope, shortDateLabel(now)].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: ThemeConfig.getTextBold20(context).copyWith(
            color: ThemeConfig.getPrimaryColor(context),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          line,
          style: ThemeConfig.getTextLight12(context).copyWith(
            color: ThemeConfig.getSubtleTextColor(context),
          ),
        ),
      ],
    );
  }
}