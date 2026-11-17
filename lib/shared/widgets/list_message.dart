import 'package:flutter/material.dart';
import 'package:saviewgo/core/theme/theme_config.dart';

/// Estado de una lista: cargando, vacía o con error. Va dentro de un
/// ListView para que jalar hacia abajo (RefreshIndicator) siga funcionando.
class ListMessage extends StatelessWidget {
  const ListMessage({
    super.key,
    this.loading = false,
    this.icon,
    this.text,
    this.actionLabel,
    this.onAction,
  });

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
          height: 320,
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

/// Fila de botones de filtro que se desplaza en horizontal.
class PillRow<T> extends StatelessWidget {
  const PillRow({
    super.key,
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelected,
  });

  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final primary = ThemeConfig.getPrimaryColor(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final value in values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Material(
                color: value == selected ? primary.withValues(alpha: 0.1) : Colors.transparent,
                shape: StadiumBorder(
                  side: BorderSide(
                    color: value == selected
                        ? primary
                        : ThemeConfig.getBorderColorStrong(context),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => onSelected(value),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    child: Text(
                      label(value),
                      style: value == selected
                          ? ThemeConfig.getTextBold12(context)
                          : ThemeConfig.getTextLight12(context),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
