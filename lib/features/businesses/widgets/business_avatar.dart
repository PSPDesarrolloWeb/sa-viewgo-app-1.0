import 'package:flutter/material.dart';
import 'package:saviewgo/core/theme/colors.dart';
import 'package:saviewgo/core/theme/theme_config.dart';

/// Logo del negocio, o su inicial si no tiene imagen o no carga.
class BusinessAvatar extends StatelessWidget {
  const BusinessAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 44,
  });

  final String name;
  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      color: AppColors.primary.withValues(alpha: 0.16),
      child: Text(
        initial,
        style: ThemeConfig.getTextBold16(context).copyWith(
          color: ThemeConfig.getPrimaryColor(context),
        ),
      ),
    );

    final url = imageUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: url == null || url.isEmpty
          ? fallback
          : Image.network(
              url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              // Se pide reducida: la lista no necesita la imagen completa.
              cacheWidth: (size * 3).round(),
              errorBuilder: (_, __, ___) => fallback,
            ),
    );
  }
}
