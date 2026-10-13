import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:saviewgo/app/app_config.dart';
import 'package:saviewgo/app/app_router.dart';
import 'package:saviewgo/core/theme/colors.dart';
import 'package:saviewgo/core/theme/images.dart';
import 'package:saviewgo/core/theme/theme_config.dart';
import 'package:saviewgo/core/theme/theme_mode_provider.dart';
import 'package:saviewgo/features/auth/app_lock_controller.dart';
import 'package:saviewgo/features/auth/login_sheet.dart';
import 'package:saviewgo/features/session/session_context.dart';
import 'package:saviewgo/features/session/session_providers.dart';

/// Inicio de SAViewGo. Sin sesión, lleva al formulario de acceso.
/// Con sesión abierta y huella activada funciona como pantalla de
/// bloqueo: pide la huella al abrir y el formulario permite entrar
/// con contraseña o con otra cuenta.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  /// Altura mínima para mostrar los chips de último acceso y soporte.
  static const _chipsMinHeight = 640.0;

  /// Altura mínima para mostrar las funciones con su descripción; por
  /// debajo se muestran solo los íconos.
  static const _featureListMinHeight = 740.0;

  bool get _locked => FirebaseAuth.instance.currentUser != null;

  @override
  void initState() {
    super.initState();
    if (_locked) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
    }
  }

  Future<void> _unlock() async {
    final ok = await ref.read(appLockProvider.notifier).unlock();
    if (ok && mounted) context.go(AppRoutes.splash);
  }

  /// Sin sesión no hay nada que desbloquear: se explica cómo activarla.
  void _explainBiometric() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Ingresa una vez con tu contraseña y marca "Activar ingreso con huella".',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final biometricAvailable =
        ref.watch(biometricAvailableProvider).value ?? false;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: ThemeConfig.getForegroundColorVG(context),
        body: Stack(
          children: [
            const Positioned.fill(child: _Backdrop()),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) => Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _TopBar(),
                      const SizedBox(height: 28),
                      const _RestrictedBadge(),
                      const SizedBox(height: 10),
                      Text(
                        'Supervisa ViewGo desde tu celular',
                        style: ThemeConfig.getTextBold20(context).copyWith(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                          letterSpacing: -0.5,
                          color: ThemeConfig.getPrimaryColor(context),
                        ),
                      ),
                      const SizedBox(height: 22),
                      if (constraints.maxHeight >= _featureListMinHeight)
                        const _FeatureList()
                      else
                        const _FeatureRow(),
                      const SizedBox(height: 18),
                      const _SessionCard(),
                      Expanded(
                        child: constraints.maxHeight >= _chipsMinHeight
                            ? const Center(child: _InfoChips())
                            : const SizedBox.shrink(),
                      ),
                      _Actions(
                        showBiometric: _locked || biometricAvailable,
                        onBiometric: _locked ? _unlock : _explainBiometric,
                      ),
                      const SizedBox(height: 12),
                      const _RecordedNotice(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ────────────────────────── Encabezado ────────────────────────── */

class _TopBar extends ConsumerWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Image.asset(AppImages.horizontalFull(context), height: 28),
        const Spacer(),
        IconButton(
          tooltip: isDark ? 'Usar tema claro' : 'Usar tema oscuro',
          style: IconButton.styleFrom(
            backgroundColor: ThemeConfig.getColor12(context),
          ),
          icon: Icon(
            isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            size: 20,
            color: ThemeConfig.getPrimaryColor(context),
          ),
          onPressed: () => ref
              .read(themeModeProvider.notifier)
              .toggle(Theme.of(context).brightness),
        ),
      ],
    );
  }
}

class _RestrictedBadge extends StatelessWidget {
  const _RestrictedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _Palette.warnBackground(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: AppColors.error,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Acceso restringido',
            style: ThemeConfig.getTextBold12(context)
                .copyWith(color: _Palette.warnText(context)),
          ),
        ],
      ),
    );
  }
}

/* ─────────────────────────── Funciones ────────────────────────── */

class _FeatureRow extends StatelessWidget {
  const _FeatureRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: _Feature(Icons.bar_chart_rounded, 'Indicadores')),
        Expanded(child: _Feature(Icons.storefront_rounded, 'Negocios')),
        Expanded(child: _Feature(Icons.notifications_none_rounded, 'Alertas')),
      ],
    );
  }
}

/// Las tres funciones con su descripción, para pantallas altas.
class _FeatureList extends StatelessWidget {
  const _FeatureList();

  static const _items = [
    (Icons.bar_chart_rounded, 'Indicadores', 'KPIs de negocios por ciudad'),
    (Icons.storefront_rounded, 'Negocios', 'Fichas, módulos y altas pendientes'),
    (Icons.notifications_none_rounded, 'Alertas', 'Pedidos, pagos y vencimientos'),
  ];

  @override
  Widget build(BuildContext context) {
    final ink = ThemeConfig.getPrimaryColor(context);
    final subtle = ThemeConfig.getSubtleTextColor(context);

    return Column(
      children: [
        for (final (icon, title, description) in _items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, size: 22, color: _Palette.accent(context)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style:
                            ThemeConfig.getTextBold14(context).copyWith(color: ink),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: ThemeConfig.getTextLight12(context)
                            .copyWith(color: subtle),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, size: 24, color: _Palette.accent(context)),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: ThemeConfig.getTextLight12(context)
              .copyWith(color: ThemeConfig.getSubtleTextColor(context)),
        ),
      ],
    );
  }
}

/* ──────────────────────────── Sesión ──────────────────────────── */

class _SessionCard extends ConsumerWidget {
  const _SessionCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final network = ref.watch(networkContextProvider);
    final device = ref.watch(deviceSummaryProvider);

    String fromNetwork(String? Function(NetworkContext) pick) => network.when(
          data: (value) => pick(value) ?? 'No disponible',
          loading: () => '…',
          error: (_, __) => 'No disponible',
        );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: _Palette.glass(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _SessionRow(
            icon: Icons.public_rounded,
            label: 'IP',
            value: fromNetwork((n) => n.ip),
          ),
          _SessionRow(
            icon: Icons.place_outlined,
            label: 'Ubicación',
            value: fromNetwork((n) => n.locationLabel),
          ),
          _SessionRow(
            icon: Icons.smartphone_rounded,
            label: 'Dispositivo',
            value: device.when(
              data: (d) => d.label,
              loading: () => '…',
              error: (_, __) => 'No disponible',
            ),
          ),
          const _SessionRow(
            icon: Icons.schedule_rounded,
            label: 'Hora',
            trailing: _LiveClock(),
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({
    required this.icon,
    required this.label,
    this.value,
    this.trailing,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String? value;
  final Widget? trailing;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final subtle = ThemeConfig.getSubtleTextColor(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: ThemeConfig.getBorderColor(context))),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: subtle),
          const SizedBox(width: 8),
          Text(
            label,
            style: ThemeConfig.getTextLight12(context).copyWith(color: subtle),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: trailing ??
                  Text(
                    value ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ThemeConfig.getTextBold12(context).copyWith(
                      color: ThemeConfig.getPrimaryColor(context),
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Hora de Ecuador continental (UTC-5, sin horario de verano), sin
/// depender de la zona configurada en el dispositivo.
class _LiveClock extends StatefulWidget {
  const _LiveClock();

  @override
  State<_LiveClock> createState() => _LiveClockState();
}

class _LiveClockState extends State<_LiveClock> {
  static final _format = DateFormat('HH:mm:ss');
  late Timer _timer;

  DateTime get _ecuadorNow =>
      DateTime.now().toUtc().subtract(const Duration(hours: 5));

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _format.format(_ecuadorNow),
      style: ThemeConfig.getTextBold12(context).copyWith(
        color: ThemeConfig.getPrimaryColor(context),
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

/* ───────────────────── Último acceso y soporte ───────────────────── */

class _InfoChips extends ConsumerWidget {
  const _InfoChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastAccess = ref.watch(lastAccessProvider);

    return Row(
      children: [
        Expanded(
          child: _InfoChip(
            icon: Icons.history_rounded,
            label: 'Último acceso',
            value: lastAccess.when(
              data: _formatLastAccess,
              loading: () => '…',
              error: (_, __) => '—',
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: _InfoChip(
            icon: Icons.headset_mic_outlined,
            label: 'Soporte',
            value: AppConfig.supportHours,
            onTap: openSupportEmail,
          ),
        ),
      ],
    );
  }

  static String _formatLastAccess(LastAccess? access) {
    if (access == null) return 'Primer acceso';

    final now = DateTime.now();
    final at = access.at;
    final days = DateTime(now.year, now.month, now.day)
        .difference(DateTime(at.year, at.month, at.day))
        .inDays;
    final day = switch (days) {
      0 => 'Hoy',
      1 => 'Ayer',
      _ => DateFormat('d MMM', 'es').format(at),
    };
    return '$day, ${DateFormat('HH:mm').format(at)}';
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final subtle = ThemeConfig.getSubtleTextColor(context);

    return Material(
      color: _Palette.glass(context),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 15, color: subtle),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: ThemeConfig.getTextLight12(context)
                        .copyWith(color: subtle),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ThemeConfig.getTextBold13(context)
                    .copyWith(color: ThemeConfig.getPrimaryColor(context)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ─────────────────────────── Acciones ─────────────────────────── */

class _Actions extends StatelessWidget {
  const _Actions({required this.showBiometric, required this.onBiometric});

  /// Visible si el dispositivo tiene biometría o hay una sesión bloqueada.
  final bool showBiometric;
  final VoidCallback onBiometric;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: () => showLoginSheet(context),
            style: primaryButtonStyle(context),
            icon: const Icon(Icons.login_rounded, size: 20),
            label: const Text('Ingresar al panel'),
          ),
        ),
        if (showBiometric) ...[
          const SizedBox(width: 10),
          Tooltip(
            message: 'Ingresar con huella',
            child: SizedBox(
              width: 50,
              height: 50,
              child: OutlinedButton(
                onPressed: onBiometric,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: _Palette.glass(context),
                  side: BorderSide(
                    color: ThemeConfig.getBorderColorStrong(context),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Icon(
                  Icons.fingerprint_rounded,
                  size: 26,
                  color: ThemeConfig.getPrimaryColor(context),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _RecordedNotice extends StatelessWidget {
  const _RecordedNotice();

  @override
  Widget build(BuildContext context) {
    final color = _Palette.warnText(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.verified_user_outlined, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          'Esta sesión está siendo registrada.',
          style: ThemeConfig.getTextLight12(context).copyWith(color: color),
        ),
      ],
    );
  }
}

/* ──────────────────────────── Fondo ───────────────────────────── */

/// Manchas de color difuminadas y la ruta punteada de la app de
/// clientes. Un solo filtro de desenfoque para todas las manchas.
class _Backdrop extends StatelessWidget {
  const _Backdrop();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final green = AppColors.primary.withValues(alpha: isDark ? 0.26 : 0.34);
    final orange = AppColors.secondary.withValues(alpha: isDark ? 0.14 : 0.16);

    return RepaintBoundary(
      child: Stack(
        children: [
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: 70,
                sigmaY: 70,
                tileMode: TileMode.decal,
              ),
              child: Stack(
                children: [
                  Positioned(top: -90, right: -100, child: _Blob(280, green)),
                  Positioned(top: 320, left: -130, child: _Blob(250, orange)),
                  Positioned(bottom: -80, right: -60, child: _Blob(230, green)),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _RoutePainter(
                color: ThemeConfig.getPrimaryColor(context)
                    .withValues(alpha: 0.08),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob(this.size, this.color);

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

/// Trazo curvo punteado, el mismo guiño a "ruta" del home de clientes.
class _RoutePainter extends CustomPainter {
  _RoutePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(-20, size.height * 0.24)
      ..quadraticBezierTo(
        size.width * 0.55,
        size.height * 0.04,
        size.width + 20,
        size.height * 0.30,
      );

    const dash = 6.0;
    const gap = 8.0;
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = math.min(distance + dash, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) =>
      oldDelegate.color != color;
}

/* ─────────────────────────── Colores ──────────────────────────── */

abstract final class _Palette {
  /// Superficie semitransparente para que el fondo se note detrás.
  static Color glass(BuildContext context) => ThemeConfig.getCustomColor(
        context,
        AppColors.viewGoColorBGLight.withValues(alpha: 0.85),
        AppColors.viewGoColorBGDark.withValues(alpha: 0.7),
      );

  static Color warnBackground(BuildContext context) =>
      ThemeConfig.getCustomColor(
        context,
        AppColors.errorContainer,
        AppColors.darkErrorContainer,
      );

  static Color warnText(BuildContext context) => ThemeConfig.getCustomColor(
        context,
        AppColors.onErrorContainer,
        AppColors.errorContainer,
      );

  static Color accent(BuildContext context) => ThemeConfig.getCustomColor(
        context,
        AppColors.onPrimaryFixedVariant,
        AppColors.primary,
      );
}