import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saviewgo/core/security/biometric_service.dart';
import 'package:saviewgo/core/theme/colors.dart';
import 'package:saviewgo/features/transfers/receipt_bytes.dart';
import 'package:saviewgo/core/theme/theme_config.dart';
import 'package:saviewgo/features/transfers/transfer_item.dart';
import 'package:saviewgo/features/transfers/transfers_providers.dart';
import 'package:saviewgo/features/transfers/transfers_repository.dart';
import 'package:saviewgo/shared/utils/input_rules.dart';
import 'package:url_launcher/url_launcher.dart';

/// Detalle de un pago por transferencia: monto, datos, comprobante y, si
/// está por validar, los botones para validar o rechazar. Se cierra
/// devolviendo el mensaje que la pantalla muestra al terminar.
class TransferSheet extends ConsumerWidget {
  const TransferSheet({super.key, required this.item});

  final TransferItem item;

  Future<void> _confirm(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ConfirmDialog(item: item),
    );
    if (ok == true && context.mounted) {
      Navigator.of(context).pop('Pago validado · ${item.title}');
    }
  }

  Future<void> _reject(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _RejectDialog(item: item),
    );
    if (ok == true && context.mounted) {
      Navigator.of(context).pop('Pago rechazado · ${item.title}');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subtle = ThemeConfig.getSubtleTextColor(context);
    final busy = ref.watch(
      transfersProvider.select((s) => s.busyIds.contains(item.id)),
    );
    final receipt = ref.watch(transferReceiptProvider(item));

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.title, style: ThemeConfig.getTextBold18(context)),
            const SizedBox(height: 2),
            Text(
              [item.kind.label, if (item.subtitle.isNotEmpty) item.subtitle].join(' · '),
              style: ThemeConfig.getTextLight12(context).copyWith(color: subtle),
            ),
            const SizedBox(height: 16),
            Text(
              item.amount == 0 ? 'Gratis' : '\$${item.amount.toStringAsFixed(2)}',
              style: ThemeConfig.getTextBold20(context).copyWith(fontSize: 28),
            ),
            const SizedBox(height: 12),
            for (final (label, value) in item.lines) _Line(label, value),
            if (item.rejectionReason != null) _Line('Motivo del rechazo', item.rejectionReason!),
            if (item.warning != null) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      size: 18, color: AppColors.septenary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.warning!,
                      style: ThemeConfig.getTextLight12(context)
                          .copyWith(color: AppColors.septenary),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Text('Comprobante', style: ThemeConfig.getTextBold14(context)),
            const SizedBox(height: 8),
            receipt.when(
              loading: () => const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (_, __) => _Hint(
                'No se pudo cargar el comprobante.',
                onRetry: () => ref.invalidate(transferReceiptProvider(item)),
              ),
              data: (r) => r == null
                  ? _Hint(item.amount == 0
                      ? 'Es un pago gratuito: no lleva comprobante.'
                      : 'Este pago no tiene comprobante.')
                  : _ReceiptView(receipt: r),
            ),
            if (item.canResolve) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: busy ? null : () => _reject(context),
                      child: const Text('Rechazar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: busy ? null : () => _confirm(context),
                      child: busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(item.kind == TransferKind.events ? 'Aprobar' : 'Validar pago'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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

class _Hint extends StatelessWidget {
  const _Hint(this.text, {this.onRetry});

  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: ThemeConfig.getTextLight12(context).copyWith(
              color: ThemeConfig.getSubtleTextColor(context),
            ),
          ),
        ),
        if (onRetry != null) TextButton(onPressed: onRetry, child: const Text('Reintentar')),
      ],
    );
  }
}

class _ReceiptView extends ConsumerWidget {
  const _ReceiptView({required this.receipt});

  final TransferReceipt receipt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (receipt.isPdf) {
      return OutlinedButton.icon(
        icon: const Icon(Icons.picture_as_pdf_outlined),
        label: const Text('Abrir comprobante (PDF)'),
        onPressed: () => launchUrl(
          Uri.parse(receipt.url),
          mode: LaunchMode.externalApplication,
        ),
      );
    }
    // Los bytes se descargan a memoria: el comprobante no queda en el disco.
    final bytes = ref.watch(receiptBytesProvider(receipt.url));
    return bytes.when(
      loading: () => const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => _Hint(
        'No se pudo mostrar la imagen del comprobante.',
        onRetry: () => ref.invalidate(receiptBytesProvider(receipt.url)),
      ),
      data: (data) => GestureDetector(
        onTap: () => showDialog<void>(
          context: context,
          builder: (_) => Dialog.fullscreen(
            backgroundColor: Colors.black,
            child: Stack(
              children: [
                Positioned.fill(
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 5,
                    child: Image.memory(data, fit: BoxFit.contain),
                  ),
                ),
                SafeArea(
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          // `contain`: el comprobante se ve completo. Con `cover` se recortaba
          // por arriba y se perdía el monto, que es lo que se compara.
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 420),
            child: Image.memory(
              data,
              width: double.infinity,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  const _Hint('El archivo del comprobante no es una imagen válida.'),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Diálogos ──────────────────────────────────────────────────────────

void _showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

class _ConfirmDialog extends ConsumerStatefulWidget {
  const _ConfirmDialog({required this.item});

  final TransferItem item;

  @override
  ConsumerState<_ConfirmDialog> createState() => _ConfirmDialogState();
}

class _ConfirmDialogState extends ConsumerState<_ConfirmDialog> {
  bool _submitting = false;

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    // Validar o aprobar no se puede deshacer: antes se confirma que quien
    // tiene el teléfono es su dueño (huella, rostro o PIN del dispositivo).
    // Es local: no usa Firebase.
    final verified = await ref.read(biometricServiceProvider).authenticate(
          widget.item.kind == TransferKind.events
              ? 'Confirma para aprobar y emitir los tickets'
              : 'Confirma para validar el pago',
        );
    if (!mounted) return;
    if (!verified) {
      setState(() => _submitting = false);
      _showError(
        context,
        'No se confirmó tu identidad. Usa tu huella o el PIN del dispositivo.',
      );
      return;
    }

    final error = await ref.read(transfersProvider.notifier).confirm(widget.item);
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _submitting = false);
      _showError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final events = widget.item.kind == TransferKind.events;
    return AlertDialog(
      title: Text(events ? 'Aprobar y emitir tickets' : 'Validar pago'),
      content: Text(widget.item.confirmText),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(events ? 'Sí, aprobar' : 'Sí, validar'),
        ),
      ],
    );
  }
}

class _RejectDialog extends ConsumerStatefulWidget {
  const _RejectDialog({required this.item});

  final TransferItem item;

  @override
  ConsumerState<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends ConsumerState<_RejectDialog> {
  final _reason = TextEditingController();
  bool _submitting = false;

  TransferSource get _source => transferSourceFor(widget.item.kind);

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  bool get _valid {
    final length = cleanReason(_reason.text).length;
    return length >= _source.minReason && length <= _source.maxReason;
  }

  Future<void> _submit() async {
    if (_submitting || !_valid) return;
    setState(() => _submitting = true);
    final error = await ref
        .read(transfersProvider.notifier)
        .reject(widget.item, cleanReason(_reason.text));
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _submitting = false);
      _showError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rechazar pago'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'El cliente verá el motivo.',
            style: ThemeConfig.getTextLight12(context).copyWith(
              color: ThemeConfig.getSubtleTextColor(context),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reason,
            enabled: !_submitting,
            autofocus: true,
            minLines: 2,
            maxLines: 4,
            inputFormatters: reasonInputFormatters(maxLength: _source.maxReason),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Motivo',
              hintText: 'Ej. El monto no coincide con el banco',
              helperText: _source.minReason > 1
                  ? 'Mínimo ${_source.minReason} caracteres'
                  : null,
              counterText: '',
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          onPressed: _submitting || !_valid ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Rechazar'),
        ),
      ],
    );
  }
}
