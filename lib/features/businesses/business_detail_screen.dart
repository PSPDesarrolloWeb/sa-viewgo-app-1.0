import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saviewgo/core/theme/colors.dart';
import 'package:saviewgo/core/theme/theme_config.dart';
import 'package:saviewgo/features/businesses/business_categories.dart';
import 'package:saviewgo/features/businesses/business_model.dart';
import 'package:saviewgo/features/businesses/businesses_providers.dart';
import 'package:saviewgo/features/businesses/widgets/business_avatar.dart';
import 'package:saviewgo/features/businesses/widgets/module_dot.dart';
import 'package:saviewgo/features/cities/cities_providers.dart';
import 'package:saviewgo/features/cities/city_model.dart';
import 'package:saviewgo/features/dashboard/widgets/dashboard_card.dart';
import 'package:saviewgo/features/dashboard/widgets/dashboard_section.dart';
import 'package:saviewgo/shared/utils/date_labels.dart';

/// Detalle de un negocio, solo lectura. Si llega desde la lista usa el
/// negocio que ya se leyó ([initial]) y no vuelve a consultarlo; si se abre
/// por enlace, lo lee una vez.
class BusinessDetailScreen extends ConsumerWidget {
  const BusinessDetailScreen({super.key, required this.businessId, this.initial});

  final String businessId;
  final BusinessModel? initial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fetched = initial == null ? ref.watch(businessDetailProvider(businessId)) : null;

    Widget body;
    if (initial != null) {
      body = _Body(business: initial!);
    } else if (fetched!.isLoading) {
      body = const Center(child: CircularProgressIndicator(strokeWidth: 2));
    } else if (fetched.hasError) {
      body = _Message(
        icon: Icons.cloud_off_rounded,
        text: 'No se pudo cargar el negocio.',
        onRetry: () => ref.invalidate(businessDetailProvider(businessId)),
      );
    } else if (fetched.value == null) {
      body = const _Message(icon: Icons.search_off_rounded, text: 'Este negocio ya no existe.');
    } else {
      body = _Body(business: fetched.value!);
    }

    return Scaffold(
      backgroundColor: ThemeConfig.getBackgroundColor(context),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: ThemeConfig.getBackgroundColor(context),
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Negocio',
          style: ThemeConfig.getTextBold18(context),
        ),
        shape: Border(bottom: BorderSide(color: ThemeConfig.getBorderColor(context))),
      ),
      body: body,
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.business});

  final BusinessModel business;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cities = ref.watch(citiesProvider).value ?? const <CityModel>[];
    final branches = ref.watch(businessBranchesProvider(business.id));
    final subtle = ThemeConfig.getSubtleTextColor(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        Row(
          children: [
            BusinessAvatar(name: business.name, imageUrl: business.profileImageUrl, size: 56),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(business.name, style: ThemeConfig.getTextBold18(context)),
                  const SizedBox(height: 2),
                  Text(
                    '${categoryLabel(business.category)} · ${business.cityLabel(cities)}',
                    style: ThemeConfig.getTextLight12(context).copyWith(color: subtle),
                  ),
                  const SizedBox(height: 6),
                  _Tag(
                    label: business.active ? 'Activo' : 'Inactivo',
                    color: business.active ? AppColors.primary : subtle,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        DashboardSection(
          title: 'Datos generales',
          child: DashboardCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Column(
              children: [
                if (business.publicUrl != null)
                  _InfoRow(
                    label: 'Enlace',
                    value: business.publicUrl!.replaceFirst('https://', ''),
                    copyable: true,
                  ),
                if (business.email.isNotEmpty)
                  _InfoRow(label: 'Correo', value: business.email, copyable: true),
                if (business.manager.isNotEmpty)
                  _InfoRow(label: 'Representante', value: business.manager),
                if (business.managerPhone.isNotEmpty)
                  _InfoRow(label: 'Teléfono', value: business.managerPhone, copyable: true),
                _InfoRow(
                  label: 'Cobertura',
                  value: business.isNational ? 'Nacional' : 'Local',
                ),
                _InfoRow(
                  label: 'Cuenta de dueño',
                  value: business.hasOwnerAccount ? 'Creada' : 'Pendiente',
                  warning: !business.hasOwnerAccount,
                ),
                if (business.createdAt != null)
                  _InfoRow(label: 'Registrado', value: _date(business.createdAt!)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        DashboardSection(
          title: 'Módulos',
          child: business.modules.isEmpty
              ? const _EmptyCard(text: 'Sin módulos contratados.')
              : DashboardCard(
                  child: Column(
                    children: [
                      for (var i = 0; i < business.modules.length; i++) ...[
                        if (i > 0)
                          Divider(height: 1, color: ThemeConfig.getBorderColor(context)),
                        _ModuleRow(state: business.modules[i]),
                      ],
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 18),
        DashboardSection(
          title: 'Sucursales',
          trailing: Text(
            business.limitBranches == null
                ? '${business.branchCount}'
                : '${business.branchCount} de ${business.limitBranches}',
            style: ThemeConfig.getTextLight12(context).copyWith(color: subtle),
          ),
          child: branches.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (_, __) => _EmptyCard(
              text: 'No se pudieron cargar las sucursales.',
              onRetry: () => ref.invalidate(businessBranchesProvider(business.id)),
            ),
            data: (list) => list.isEmpty
                ? const _EmptyCard(text: 'Sin sucursales. Falta crear la principal.')
                : DashboardCard(
                    child: Column(
                      children: [
                        for (var i = 0; i < list.length; i++) ...[
                          if (i > 0)
                            Divider(height: 1, color: ThemeConfig.getBorderColor(context)),
                          _BranchRow(branch: list[i], cities: cities),
                        ],
                      ],
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Para editar el negocio, sus módulos o planes, usa el panel web.',
          textAlign: TextAlign.center,
          style: ThemeConfig.getTextLight12(context).copyWith(color: subtle),
        ),
      ],
    );
  }

  String _date(DateTime d) => shortDateLabel(d);
}

// ── Piezas ────────────────────────────────────────────────────────────

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: ThemeConfig.getTextBold10(context).copyWith(color: color)),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.copyable = false,
    this.warning = false,
  });

  final String label;
  final String value;
  final bool copyable;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final subtle = ThemeConfig.getSubtleTextColor(context);
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(label, style: ThemeConfig.getTextLight12(context).copyWith(color: subtle)),
          ),
          Expanded(
            child: Text(
              value,
              style: ThemeConfig.getTextBold13(context).copyWith(
                color: warning ? AppColors.septenary : ThemeConfig.getPrimaryColor(context),
              ),
            ),
          ),
          if (copyable) Icon(Icons.copy_rounded, size: 14, color: subtle),
        ],
      ),
    );
    if (!copyable) return row;
    return InkWell(
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: value));
        if (!context.mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('$label copiado')));
      },
      child: row,
    );
  }
}

class _ModuleRow extends StatelessWidget {
  const _ModuleRow({required this.state});

  final BusinessModuleState state;

  @override
  Widget build(BuildContext context) {
    final subtle = ThemeConfig.getSubtleTextColor(context);
    final color = moduleStatusColor(context, state.status);
    final details = <String>[
      if (state.enabled) tierLabel(state.tier) else 'Apagado',
      if (state.isPartner) 'Partner',
      if (state.paymentPending) 'Pago pendiente',
      if (state.status == ModuleStatus.trial && state.trialEndsAt != null)
        'Prueba hasta ${shortDateLabel(state.trialEndsAt!)}',
      if (state.enabled && state.status == ModuleStatus.active && state.nextBillingDate != null)
        'Próx. cobro ${shortDateLabel(state.nextBillingDate!)}',
      if (state.status == ModuleStatus.suspended &&
          (state.suspensionReason ?? '').isNotEmpty)
        state.suspensionReason!,
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CategoryIcon(icon: Icons.apps_rounded, color: state.module.color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(state.module.label, style: ThemeConfig.getTextBold13(context)),
                const SizedBox(height: 1),
                Text(
                  details.join(' · '),
                  style: ThemeConfig.getTextLight12(context)
                      .copyWith(fontSize: 11.5, color: subtle),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _Tag(label: state.enabled ? state.status.label : 'Apagado', color: color),
        ],
      ),
    );
  }
}

class _BranchRow extends StatelessWidget {
  const _BranchRow({required this.branch, required this.cities});

  final BranchModel branch;
  final List<CityModel> cities;

  @override
  Widget build(BuildContext context) {
    final subtle = ThemeConfig.getSubtleTextColor(context);
    final city = cities.byId(branch.cityId)?.name ?? 'Ciudad';
    final title = branch.label.isEmpty ? city : '${branch.label} · $city';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.location_on_outlined, size: 18, color: subtle),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: ThemeConfig.getTextBold13(context)),
                if (branch.address.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    branch.address,
                    style: ThemeConfig.getTextLight12(context)
                        .copyWith(fontSize: 11.5, color: subtle),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (branch.isMain) const _Tag(label: 'Principal', color: AppColors.primary),
          if (!branch.active) ...[
            const SizedBox(width: 6),
            _Tag(label: 'Inactiva', color: subtle),
          ],
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.text, this.onRetry});

  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: ThemeConfig.getTextLight12(context).copyWith(
              color: ThemeConfig.getSubtleTextColor(context),
            ),
          ),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.onRetry});

  final IconData icon;
  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final subtle = ThemeConfig.getSubtleTextColor(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: subtle),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: ThemeConfig.getTextLight14(context).copyWith(color: subtle),
            ),
            if (onRetry != null)
              TextButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
