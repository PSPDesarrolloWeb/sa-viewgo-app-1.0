import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saviewgo/app/app_router.dart';
import 'package:saviewgo/core/auth/auth_providers.dart';
import 'package:saviewgo/core/theme/colors.dart';
import 'package:saviewgo/core/theme/theme_config.dart';
import 'package:saviewgo/core/theme/theme_mode_provider.dart';
import 'package:saviewgo/features/auth/app_lock_controller.dart';
import 'package:saviewgo/features/auth/app_lock_watcher.dart';
import 'package:saviewgo/features/auth/auth_repository.dart';
import 'package:saviewgo/features/cities/cities_providers.dart';
import 'package:saviewgo/features/cities/city_model.dart';
import 'package:saviewgo/features/dashboard/widgets/dashboard_card.dart';
import 'package:saviewgo/features/dashboard/widgets/dashboard_section.dart';
import 'package:saviewgo/features/session/session_providers.dart';
import 'package:saviewgo/shared/utils/date_labels.dart';
import 'package:saviewgo/shared/widgets/shell_app_bar.dart';

/// Perfil: la cuenta, la sesión de este dispositivo, la seguridad y la
/// apariencia. Todo es local o de la propia cuenta: no hay nada que afecte
/// a otras personas ni a la configuración de ViewGo.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _sendingReset = false;
  bool _signingOut = false;

  void _toast(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  /// Bloquea ya, sin cerrar la sesión: vuelve a pedir huella o PIN.
  void _lockNow() {
    ref.read(appLockProvider.notifier).lock();
    context.go(AppRoutes.login);
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String action,
    bool destructive = false,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(backgroundColor: AppColors.error)
                : null,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(action),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _sendReset(String email) async {
    if (_sendingReset) return;
    final ok = await _confirm(
      title: 'Cambiar contraseña',
      message: 'Te enviaremos un enlace a $email para crear una contraseña nueva.',
      action: 'Enviar enlace',
    );
    if (!ok || !mounted || _sendingReset) return;

    setState(() => _sendingReset = true);
    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(email);
      if (mounted) _toast('Te enviamos el enlace. Revisa tu correo.');
    } catch (_) {
      if (mounted) _toast('No se pudo enviar el enlace. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _sendingReset = false);
    }
  }

  Future<void> _signOut() async {
    if (_signingOut) return;
    final ok = await _confirm(
      title: 'Cerrar sesión',
      message: 'Se borrarán de este teléfono los datos guardados de la sesión. '
          'Para volver a entrar necesitarás tu correo y contraseña.',
      action: 'Cerrar sesión',
      destructive: true,
    );
    if (!ok || !mounted || _signingOut) return;

    setState(() => _signingOut = true);
    final router = ref.read(appRouterProvider);
    try {
      await ref.read(authRepositoryProvider).signOut();
      router.go(AppRoutes.login);
    } catch (_) {
      if (mounted) {
        setState(() => _signingOut = false);
        _toast('No se pudo cerrar la sesión. Intenta de nuevo.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(firebaseUserProvider).value;
    final claims = ref.watch(adminClaimsProvider).value;
    final cities = ref.watch(citiesProvider).value ?? const <CityModel>[];
    final device = ref.watch(deviceSummaryProvider).value;
    final session = ref.watch(registeredSessionProvider).value;
    final themeMode = ref.watch(themeModeProvider);
    final brightness = Theme.of(context).brightness;
    final subtle = ThemeConfig.getSubtleTextColor(context);

    final email = user?.email ?? '';
    final name = (user?.displayName ?? '').trim();
    final roleLabel = claims == null
        ? ''
        : claims.isGlobal
            ? 'Superadmin global'
            : 'Superadmin de ${cities.byId(claims.cityId)?.name ?? 'ciudad'}';

    return Scaffold(
      backgroundColor: ThemeConfig.getBackgroundColor(context),
      appBar: const ShellAppBar(title: 'Perfil'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          DashboardCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.18),
                  child: Text(
                    _initials(name, email),
                    style: ThemeConfig.getTextBold16(context),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (name.isNotEmpty)
                        Text(name, style: ThemeConfig.getTextBold16(context)),
                      Text(
                        email,
                        overflow: TextOverflow.ellipsis,
                        style: ThemeConfig.getTextLight12(context).copyWith(color: subtle),
                      ),
                      if (roleLabel.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(roleLabel, style: ThemeConfig.getTextBold10(context)),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          DashboardSection(
            title: 'Esta sesión',
            child: DashboardCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Column(
                children: [
                  _InfoRow('Dispositivo', device?.label ?? '—'),
                  _InfoRow('Versión de la app', device?.appVersion ?? '—'),
                  _InfoRow(
                    'Inicio de sesión',
                    session == null
                        ? '—'
                        : '${shortDateLabel(session.at)}, ${_time(session.at)}',
                  ),
                  if (session?.locationLabel != null)
                    _InfoRow('Ubicación aproximada', session!.locationLabel!),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          DashboardSection(
            title: 'Seguridad',
            child: DashboardCard(
              child: Column(
                children: [
                  _ActionRow(
                    icon: Icons.lock_outline_rounded,
                    title: 'Bloquear ahora',
                    subtitle: 'Se desbloquea con tu huella o el PIN del teléfono',
                    onTap: _lockNow,
                  ),
                  Divider(height: 1, color: ThemeConfig.getBorderColor(context)),
                  _ActionRow(
                    icon: Icons.key_outlined,
                    title: 'Cambiar contraseña',
                    subtitle: 'Te enviamos un enlace por correo',
                    loading: _sendingReset,
                    onTap: email.isEmpty ? null : () => _sendReset(email),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
            child: Text(
              'La app se bloquea sola tras ${AppLockWatcher.relockAfter.inMinutes} minutos fuera de ella.',
              style: ThemeConfig.getTextLight12(context).copyWith(color: subtle),
            ),
          ),
          const SizedBox(height: 18),
          DashboardSection(
            title: 'Apariencia',
            child: DashboardCard(
              child: SwitchListTile(
                value: brightness == Brightness.dark,
                onChanged: (_) =>
                    ref.read(themeModeProvider.notifier).toggle(brightness),
                title: Text('Tema oscuro', style: ThemeConfig.getTextBold13(context)),
                subtitle: Text(
                  themeMode == ThemeMode.system
                      ? 'Ahora sigue al sistema'
                      : 'Elegido por ti',
                  style: ThemeConfig.getTextLight12(context).copyWith(color: subtle),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _signingOut ? null : _signOut,
              icon: _signingOut
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.logout_rounded),
              label: const Text('Cerrar sesión'),
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name, String email) {
    final source = name.isNotEmpty ? name : email;
    final parts = source.split(RegExp(r'[\s@._-]+')).where((p) => p.isNotEmpty);
    final letters = parts.take(2).map((p) => p[0].toUpperCase()).join();
    return letters.isEmpty ? 'SA' : letters;
  }

  String _time(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: ThemeConfig.getTextLight12(context).copyWith(
                color: ThemeConfig.getSubtleTextColor(context),
              ),
            ),
          ),
          Expanded(child: Text(value, style: ThemeConfig.getTextBold13(context))),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.loading = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final subtle = ThemeConfig.getSubtleTextColor(context);
    return InkWell(
      onTap: loading ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 22, color: subtle),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: ThemeConfig.getTextBold13(context)),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: ThemeConfig.getTextLight12(context).copyWith(color: subtle),
                  ),
                ],
              ),
            ),
            if (loading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(Icons.chevron_right_rounded, size: 20, color: subtle),
          ],
        ),
      ),
    );
  }
}
