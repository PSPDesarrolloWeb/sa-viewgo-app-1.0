import 'package:flutter/material.dart';
import 'package:saviewgo/core/theme/colors.dart';

/// Tipos de `admin_alerts.type`. Agregar un tipo nuevo solo exige sumarlo
/// aquí con su ícono y color.
enum AlertType {
  orderCreated('order.created', Icons.shopping_cart_outlined, AppColors.quaternary),
  paymentVerified('payment.verified', Icons.check_rounded, AppColors.primary),
  paymentPendingReview('payment.pending_review', Icons.credit_card_rounded, AppColors.secondary),
  moduleTrialExpiring('module.trial_expiring', Icons.hourglass_bottom_rounded, AppColors.septenary),
  subscriptionOverdue('subscription.overdue', Icons.warning_amber_rounded, AppColors.error),
  businessPendingSetup('business.pending_setup', Icons.add_business_outlined, AppColors.senary);

  const AlertType(this.value, this.icon, this.color);

  /// Valor guardado en Firestore.
  final String value;
  final IconData icon;
  final Color color;

  static AlertType? fromValue(String value) {
    for (final t in values) {
      if (t.value == value) return t;
    }
    return null;
  }
}