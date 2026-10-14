import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saviewgo/app/app_config.dart';
import 'package:saviewgo/app/app_router.dart';
import 'package:saviewgo/core/theme/colors.dart';
import 'package:saviewgo/core/theme/theme_config.dart';
import 'package:saviewgo/features/auth/login_controller.dart';
import 'package:url_launcher/url_launcher.dart';


Future<void> showLoginSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: ThemeConfig.getBackgroundColorVG(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const LoginSheet(),
  );
}
 
Future<void> openSupportEmail() => launchUrl(
      Uri.parse(
        'mailto:${AppConfig.supportEmail}'
        '?subject=${Uri.encodeComponent('Soporte SAViewGo')}',
      ),
    );
 
ButtonStyle primaryButtonStyle(BuildContext context) => FilledButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.onPrimary,
      minimumSize: const Size.fromHeight(50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: ThemeConfig.getTextBold14(context),
    );
 
Color _linkColor(BuildContext context) => ThemeConfig.getCustomColor(
      context,
      AppColors.primaryDark,
      AppColors.darkPrimary,
    );
 
class LoginSheet extends ConsumerStatefulWidget {
  const LoginSheet({super.key});
 
  @override
  ConsumerState<LoginSheet> createState() => _LoginSheetState();
}
 
class _LoginSheetState extends ConsumerState<LoginSheet> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
 
  @override
  void initState() {
    super.initState();
    // En modo bloqueo ya hay una cuenta: se propone su correo.
    _email.text = FirebaseAuth.instance.currentUser?.email ?? '';
  }
 
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }
 
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
 
    final router = GoRouter.of(context);
    final navigator = Navigator.of(context);
 
    final ok = await ref.read(loginControllerProvider.notifier).submit(
          email: _email.text,
          password: _password.text,
        );
    if (!ok || !mounted) return;
 
    navigator.pop();
    router.go(AppRoutes.splash);
  }
 
  Future<void> _forgotPassword() async {
    final email = _email.text.trim();
    if (!email.contains('@')) {
      _formKey.currentState!.validate();
      return;
    }
    await ref.read(loginControllerProvider.notifier).requestPasswordReset(email);
  }
 
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginControllerProvider);
    final ink = ThemeConfig.getPrimaryColor(context);
    final subtle = ThemeConfig.getSubtleTextColor(context);
 
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ThemeConfig.getBorderColorStrong(context),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Acceso SuperAdmin',
                style: ThemeConfig.getTextBold20(context).copyWith(color: ink),
              ),
              const SizedBox(height: 4),
              Text(
                'Solo administradores autorizados de ViewGo.',
                style: ThemeConfig.getTextLight14(context).copyWith(color: subtle),
              ),
              const SizedBox(height: 20),
              _FieldLabel('Correo electrónico'),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                autocorrect: false,
                decoration: _inputDecoration(
                  context,
                  hint: 'admin@viewgo.ec',
                  icon: Icons.mail_outline_rounded,
                ),
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty) return 'Escribe tu correo.';
                  if (!email.contains('@')) return 'Revisa el formato del correo.';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _FieldLabel('Contraseña'),
                  const Spacer(),
                  TextButton(
                    onPressed: state.loading ? null : _forgotPassword,
                    style: TextButton.styleFrom(
                      foregroundColor: _linkColor(context),
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 28),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: ThemeConfig.getTextBold12(context),
                    ),
                    child: const Text('¿Olvidaste tu contraseña?'),
                  ),
                ],
              ),
              TextFormField(
                controller: _password,
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onFieldSubmitted: (_) => _submit(),
                decoration: _inputDecoration(
                  context,
                  hint: 'Contraseña',
                  icon: Icons.lock_outline_rounded,
                  suffix: IconButton(
                    tooltip: _obscure ? 'Mostrar contraseña' : 'Ocultar contraseña',
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (value) =>
                    (value ?? '').isEmpty ? 'Escribe tu contraseña.' : null,
              ),
              const SizedBox(height: 18),
              if (state.error != null || state.notice != null) ...[
                Text(
                  state.error ?? state.notice!,
                  style: ThemeConfig.getTextLight12(context).copyWith(
                    color: state.error != null
                        ? ThemeConfig.getCustomColor(
                            context, AppColors.error, AppColors.darkError)
                        : _linkColor(context),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              FilledButton(
                onPressed: state.loading ? null : _submit,
                style: primaryButtonStyle(context),
                child: state.loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.onPrimary,
                        ),
                      )
                    : const Text('Ingresar al panel'),
              ),
              const SizedBox(height: 14),
              Center(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '¿Problemas para ingresar? ',
                      style: ThemeConfig.getTextLight12(context)
                          .copyWith(color: subtle),
                    ),
                    GestureDetector(
                      onTap: openSupportEmail,
                      child: Text(
                        'Contactar soporte interno',
                        style: ThemeConfig.getTextBold12(context)
                            .copyWith(color: _linkColor(context)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
 
class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
 
  final String text;
 
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 2, bottom: 6),
        child: Text(
          text,
          style: ThemeConfig.getTextBold13(context)
              .copyWith(color: ThemeConfig.getPrimaryColor(context)),
        ),
      );
}
 
InputDecoration _inputDecoration(
  BuildContext context, {
  required String hint,
  required IconData icon,
  Widget? suffix,
}) {
  OutlineInputBorder border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );
  final error =
      ThemeConfig.getCustomColor(context, AppColors.error, AppColors.darkError);
 
  return InputDecoration(
    hintText: hint,
    hintStyle: ThemeConfig.getTextHint13(context),
    prefixIcon: Icon(icon, size: 20),
    suffixIcon: suffix,
    filled: true,
    fillColor: ThemeConfig.getForegroundColorVG(context),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    enabledBorder: border(ThemeConfig.getBorderColorStrong(context)),
    focusedBorder: border(AppColors.primary, 1.6),
    errorBorder: border(error),
    focusedErrorBorder: border(error, 1.6),
  );
}
 