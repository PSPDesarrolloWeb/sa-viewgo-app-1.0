import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saviewgo/app/app_router.dart';
import 'package:saviewgo/core/theme/colors.dart';
import 'package:saviewgo/core/theme/images.dart';
import 'package:saviewgo/core/theme/theme_config.dart';
import 'package:saviewgo/features/splash/startup_controller.dart';
import 'package:saviewgo/features/splash/startup_state.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  static const contentWidth = 220.0;
  static const _exitDelay = Duration(milliseconds: 400);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(startupControllerProvider);

    ref.listen<StartupOutcome>(
      startupControllerProvider.select((s) => s.outcome),
      (_, outcome) async {
        switch (outcome) {
          case StartupOutcome.ready:
            await Future<void>.delayed(_exitDelay);
            if (context.mounted) context.go(AppRoutes.home);
          case StartupOutcome.signedOut:
          case StartupOutcome.locked:
            context.go(AppRoutes.login);
          default:
            break;
        }
      },
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: ThemeConfig.getBackgroundColor(context),
        body: SafeArea(
          child: Center(
            child: Column(
              children: [
                const Spacer(flex: 2),
                Image.asset(AppImages.full(context), width: 160),
                const SizedBox(height: 36),
                SizedBox(
                  width: contentWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ProgressBar(
                        progress: state.progress,
                        failed: state.hasFailed,
                      ),
                      const SizedBox(height: 20),
                      for (final step in StartupStep.values)
                        _StepRow(step: step, status: state.steps[step]!),
                    ],
                  ),
                ),
                if (state.outcome == StartupOutcome.failed ||
                    state.outcome == StartupOutcome.noAccess)
                  _FailureActions(state: state),
                const Spacer(flex: 3),
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Image.asset(AppImages.logoPSP(context), height: 18),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress, required this.failed});

  final double progress;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    final fill = failed ? _StepColors.failed(context) : AppColors.primary;

    return TweenAnimationBuilder<double>(
      tween: Tween(end: progress),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: value,
          minHeight: 4,
          color: fill,
          backgroundColor: ThemeConfig.getColor12(context),
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step, required this.status});

  final StartupStep step;
  final StepStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      StepStatus.done => _StepColors.done(context),
      StepStatus.running => ThemeConfig.getPrimaryColor(context),
      StepStatus.failed => _StepColors.failed(context),
      StepStatus.pending ||
      StepStatus.skipped =>
        ThemeConfig.getColor24(context),
    };

    final icon = switch (status) {
      StepStatus.running => SizedBox(
          width: 16,
          height: 16,
          child: Padding(
            padding: const EdgeInsets.all(1.5),
            child: CircularProgressIndicator(strokeWidth: 2, color: color),
          ),
        ),
      StepStatus.done =>
        Icon(Icons.check_circle_rounded, size: 16, color: color),
      StepStatus.failed => Icon(Icons.error_rounded, size: 16, color: color),
      StepStatus.pending =>
        Icon(Icons.radio_button_unchecked_rounded, size: 16, color: color),
      StepStatus.skipped =>
        Icon(Icons.remove_circle_outline_rounded, size: 16, color: color),
    };

    return Semantics(
      liveRegion: status == StepStatus.running,
      label: '${step.label}: ${_statusLabel(status)}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: KeyedSubtree(key: ValueKey(status), child: icon),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: ThemeConfig.getTextLight12(context).copyWith(
                  color: color,
                  fontWeight: status == StepStatus.running
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
                child: Text(step.label),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(StepStatus status) => switch (status) {
        StepStatus.pending => 'pendiente',
        StepStatus.running => 'en curso',
        StepStatus.done => 'listo',
        StepStatus.failed => 'falló',
        StepStatus.skipped => 'omitido',
      };
}

class _FailureActions extends ConsumerWidget {
  const _FailureActions({required this.state});

  final StartupState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noAccess = state.outcome == StartupOutcome.noAccess;

    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: SizedBox(
        width: SplashScreen.contentWidth,
        child: Column(
          children: [
            if (state.message != null)
              Text(
                state.message!,
                textAlign: TextAlign.center,
                style: ThemeConfig.getTextLight12(context).copyWith(
                  color: ThemeConfig.getSubtleTextColor(context),
                ),
              ),
            const SizedBox(height: 14),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: ThemeConfig.getPrimaryColor(context),
                side: BorderSide(
                  color: ThemeConfig.getBorderColorStrong(context),
                ),
                textStyle: ThemeConfig.getTextBold13(context),
                shape: const StadiumBorder(),
              ),
              onPressed: noAccess
                  ? () => context.go(AppRoutes.login)
                  : () => ref.read(startupControllerProvider.notifier).run(),
              child: Text(noAccess ? 'Ir al inicio de sesión' : 'Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Verde y rojo con contraste suficiente en cada tema: los tonos base
/// (72CF59, DC2626) se leen mal como texto pequeño sobre F1F5F9.
abstract final class _StepColors {
  static Color done(BuildContext context) => ThemeConfig.getCustomColor(
        context,
        AppColors.primaryDark,
        AppColors.darkPrimary,
      );

  static Color failed(BuildContext context) => ThemeConfig.getCustomColor(
        context,
        AppColors.error,
        AppColors.darkError,
      );
}