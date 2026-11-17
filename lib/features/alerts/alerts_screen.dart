import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saviewgo/app/app_router.dart';
import 'package:saviewgo/core/theme/theme_config.dart';
import 'package:saviewgo/features/alerts/admin_notification.dart';
import 'package:saviewgo/features/alerts/alert_type.dart';
import 'package:saviewgo/features/alerts/alerts_providers.dart';
import 'package:saviewgo/features/cities/city_scope_chip.dart';
import 'package:saviewgo/features/transfers/transfer_item.dart';
import 'package:saviewgo/features/transfers/transfers_providers.dart';
import 'package:saviewgo/features/dashboard/widgets/dashboard_card.dart';
import 'package:saviewgo/shared/utils/date_labels.dart';
import 'package:saviewgo/shared/utils/theme_x.dart';
import 'package:saviewgo/shared/widgets/shell_app_bar.dart';

/// Pestaña Alertas: bandeja de `adminNotifications` (hoy, transferencias
/// por validar). 20 por página; cada superadmin marca como leído lo suyo.
class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 400) {
        ref.read(alertsProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _markAll() async {
    final ok = await ref.read(alertsProvider.notifier).markAllRead();
    if (!ok && mounted) _toast('No se pudieron marcar como leídas.');
  }

  Future<void> _open(AdminNotification n) async {
    // Marca como leído sin esperar: la hoja se abre de inmediato.
    final marking = ref.read(alertsProvider.notifier).markRead([n.id]);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: ThemeConfig.getBackgroundColor(context),
      builder: (_) => _AlertSheet(notification: n),
    );
    final ok = await marking;
    if (!ok && mounted) _toast('No se pudo marcar como leída.');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(alertsProvider);
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final unread = state.items.where((n) => !n.isReadBy(uid)).length;

    return Scaffold(
      backgroundColor: ThemeConfig.getBackgroundColor(context),
      appBar: ShellAppBar(
        title: 'Alertas',
        actions: [
          IconButton(
            tooltip: 'Marcar todas como leídas',
            visualDensity: VisualDensity.compact,
            onPressed: unread == 0 || state.marking ? null : _markAll,
            icon: state.marking
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.done_all_rounded, size: 22),
          ),
          const CityScopeChip(),
        ],
      ),
      body: RefreshIndicator(
        color: context.accentText,
        onRefresh: () => ref.read(alertsProvider.notifier).refresh(),
        child: _body(state, uid),
      ),
    );
  }

  Widget _body(AlertsState state, String uid) {
    if (state.loading) return const _Message(loading: true);
    if (state.error) {
      return _Message(
        icon: Icons.cloud_off_rounded,
        text: 'No se pudieron cargar las alertas.',
        actionLabel: 'Reintentar',
        onAction: () => ref.read(alertsProvider.notifier).refresh(),
      );
    }
    if (state.items.isEmpty) {
      return const _Message(
        icon: Icons.notifications_none_rounded,
        text: 'No hay alertas por ahora.',
      );
    }

    final extra = (state.loadingMore || state.moreError || state.hasMore) ? 1 : 0;
    return ListView.separated(
      controller: _scroll,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: state.items.length + extra,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index >= state.items.length) {
          return state.moreError
              ? Center(
                  child: TextButton(
                    onPressed: () => ref.read(alertsProvider.notifier).loadMore(),
                    child: const Text('No se pudo cargar más. Reintentar'),
                  ),
                )
              : const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
        }
        final n = state.items[index];
        return _AlertTile(
          notification: n,
          unread: !n.isReadBy(uid),
          onTap: () => _open(n),
        );
      },
    );
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({
    required this.notification,
    required this.unread,
    required this.onTap,
  });

  final AdminNotification notification;
  final bool unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const type = AlertType.paymentPendingReview;
    final subtle = ThemeConfig.getSubtleTextColor(context);
    return DashboardCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CategoryIcon(icon: type.icon, color: type.color, size: 34),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: unread
                      ? ThemeConfig.getTextBold14(context)
                      : ThemeConfig.getTextLight14(context),
                ),
                if (notification.body.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    notification.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: ThemeConfig.getTextLight12(context).copyWith(color: subtle),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  '${notification.moduleLabel} · ${relativeTime(notification.createdAt)}',
                  style: ThemeConfig.getTextLight10(context).copyWith(color: subtle),
                ),
              ],
            ),
          ),
          if (unread)
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: type.color,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AlertSheet extends ConsumerWidget {
  const _AlertSheet({required this.notification});

  final AdminNotification notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const type = AlertType.paymentPendingReview;
    final subtle = ThemeConfig.getSubtleTextColor(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CategoryIcon(icon: type.icon, color: type.color, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(notification.title, style: ThemeConfig.getTextBold16(context)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (notification.body.isNotEmpty)
              Text(notification.body, style: ThemeConfig.getTextLight14(context)),
            const SizedBox(height: 12),
            Text(
              '${notification.moduleLabel} · ${shortDateLabel(notification.createdAt)}, '
              '${relativeTime(notification.createdAt)}',
              style: ThemeConfig.getTextLight12(context).copyWith(color: subtle),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  // Abre la pestaña Transferencias en el flujo del aviso.
                  final kind = TransferKind.fromKey(notification.module);
                  if (kind != null) {
                    final filters = ref.read(transferFiltersProvider);
                    ref
                        .read(transferFiltersProvider.notifier)
                        .set(filters.copyWith(kind: kind, bucket: TransferBucket.toValidate));
                  }
                  Navigator.of(context).pop();
                  context.go(AppRoutes.transfers);
                },
                child: const Text('Revisar transferencia'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({this.loading = false, this.icon, this.text, this.actionLabel, this.onAction});

  final bool loading;
  final IconData? icon;
  final String? text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final subtle = ThemeConfig.getSubtleTextColor(context);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: 360,
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 40, color: subtle),
                        const SizedBox(height: 12),
                        Text(
                          text ?? '',
                          textAlign: TextAlign.center,
                          style: ThemeConfig.getTextLight14(context).copyWith(color: subtle),
                        ),
                        if (onAction != null)
                          TextButton(onPressed: onAction, child: Text(actionLabel ?? '')),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
