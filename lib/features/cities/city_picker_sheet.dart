import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saviewgo/core/theme/theme_config.dart';
import 'package:saviewgo/features/cities/cities_providers.dart';
import 'package:saviewgo/features/cities/city_model.dart';
import 'package:saviewgo/shared/utils/theme_x.dart';

/// Abre el selector de ciudad del superadmin_global.
Future<void> showCityPickerSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: ThemeConfig.getForegroundColor(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.75,
      child: const _CityPicker(),
    ),
  );
}

class _CityPicker extends ConsumerStatefulWidget {
  const _CityPicker();

  @override
  ConsumerState<_CityPicker> createState() => _CityPickerState();
}

class _CityPickerState extends ConsumerState<_CityPicker> {
  String _query = '';

  void _pick(String? cityId) {
    ref.read(selectedCityIdProvider.notifier).select(cityId);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cities = ref.watch(citiesProvider);
    final selectedId = ref.watch(selectedCityIdProvider);
    final subtle = ThemeConfig.getSubtleTextColor(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Text(
            'Ver ciudad',
            style: ThemeConfig.getTextBold18(context).copyWith(
              color: ThemeConfig.getPrimaryColor(context),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            onChanged: (value) => setState(() => _query = value),
            textInputAction: TextInputAction.search,
            style: ThemeConfig.getTextLight14(context).copyWith(
              color: ThemeConfig.getPrimaryColor(context),
            ),
            decoration: InputDecoration(
              hintText: 'Buscar por nombre o provincia',
              hintStyle: ThemeConfig.getTextHint13(context),
              prefixIcon: Icon(Icons.search_rounded, size: 20, color: subtle),
              isDense: true,
              filled: true,
              fillColor: ThemeConfig.getSurfaceColor(context),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: cities.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => _Message(
              text: 'No pudimos cargar las ciudades.',
              color: subtle,
            ),
            data: (list) {
              final filtered = list.where((c) => c.matchesSearch(_query)).toList();
              final showAll = _query.trim().isEmpty;

              if (filtered.isEmpty && !showAll) {
                return _Message(text: 'Sin resultados para "$_query".', color: subtle);
              }

              return ListView(
                padding: const EdgeInsets.only(bottom: 16),
                children: [
                  if (showAll)
                    _CityTile(
                      icon: Icons.public_rounded,
                      title: 'Todas las ciudades',
                      subtitle: '${list.length} activas',
                      selected: selectedId == null,
                      onTap: () => _pick(null),
                    ),
                  for (final CityModel city in filtered)
                    _CityTile(
                      icon: Icons.location_on_outlined,
                      title: city.name,
                      subtitle: city.province,
                      selected: city.id == selectedId,
                      onTap: () => _pick(city.id),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CityTile extends StatelessWidget {
  const _CityTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = context.accentText;
    final ink = ThemeConfig.getPrimaryColor(context);

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: selected ? context.accentSoft : ThemeConfig.getSurfaceColor(context),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: selected ? accent : ink),
      ),
      title: Text(
        title,
        style: ThemeConfig.getTextBold14(context).copyWith(color: ink),
      ),
      subtitle: subtitle.isEmpty
          ? null
          : Text(
              subtitle,
              style: ThemeConfig.getTextLight12(context).copyWith(
                color: ThemeConfig.getSubtleTextColor(context),
              ),
            ),
      trailing: selected ? Icon(Icons.check_rounded, color: accent) : null,
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: ThemeConfig.getTextLight14(context).copyWith(color: color),
        ),
      ),
    );
  }
}