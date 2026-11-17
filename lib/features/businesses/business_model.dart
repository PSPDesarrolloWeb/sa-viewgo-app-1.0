import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saviewgo/features/cities/city_model.dart';
import 'package:saviewgo/shared/models/business_module.dart';

/// Marcador de cobertura nacional dentro de `cityIds`.
const nationalCityId = '_national';

enum ModuleStatus {
  active('Activo'),
  trial('Prueba'),
  suspended('Suspendido'),
  disabled('Desactivado');

  const ModuleStatus(this.label);
  final String label;

  static ModuleStatus fromValue(Object? value) {
    for (final s in values) {
      if (s.name == value) return s;
    }
    return ModuleStatus.disabled;
  }
}

String tierLabel(String? tier) => switch (tier) {
      'free' => 'Gratis',
      'basic' => 'Basic',
      'pro' => 'Pro',
      'business' => 'Business',
      'enterprise' => 'Enterprise',
      _ => '—',
    };

/// Estado de un módulo dentro de `business.modules.{key}`.
class BusinessModuleState {
  const BusinessModuleState({
    required this.module,
    required this.enabled,
    required this.status,
    this.tier,
    this.trialEndsAt,
    this.nextBillingDate,
    this.isPartner = false,
    this.paymentPending = false,
    this.suspensionReason,
  });

  factory BusinessModuleState.fromMap(BusinessModule module, Map<String, dynamic> data) {
    return BusinessModuleState(
      module: module,
      enabled: data['enabled'] == true,
      status: ModuleStatus.fromValue(data['status']),
      tier: data['tier'] as String?,
      trialEndsAt: (data['trialEndsAt'] as Timestamp?)?.toDate(),
      nextBillingDate: (data['nextBillingDate'] as Timestamp?)?.toDate(),
      isPartner: data['accessType'] == 'partner',
      paymentPending: data['paymentStatus'] == 'pending',
      suspensionReason: data['suspensionReason'] as String?,
    );
  }

  final BusinessModule module;
  final bool enabled;
  final ModuleStatus status;
  final String? tier;
  final DateTime? trialEndsAt;
  final DateTime? nextBillingDate;
  final bool isPartner;
  final bool paymentPending;
  final String? suspensionReason;
}

/// Documento `business/{businessId}`. Equivale a IBusiness del panel web.
/// Solo lectura: lo que la app superadmin necesita para listar y revisar.
class BusinessModel {
  const BusinessModel({
    required this.id,
    required this.name,
    required this.handle,
    required this.category,
    required this.active,
    required this.coverage,
    required this.cityIds,
    required this.mainCityId,
    required this.branchCount,
    required this.hasOwnerAccount,
    required this.modules,
    this.email = '',
    this.manager = '',
    this.managerPhone = '',
    this.profileImageUrl,
    this.limitBranches,
    this.createdAt,
  });

  factory BusinessModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};

    final rawModules = data['modules'];
    final modules = <BusinessModuleState>[];
    if (rawModules is Map) {
      for (final module in BusinessModule.values) {
        final value = rawModules[module.key];
        if (value is Map<String, dynamic>) {
          modules.add(BusinessModuleState.fromMap(module, value));
        }
      }
    }

    final rep = data['representative'];
    final limits = data['limits'];
    final image = data['profileImage'];

    return BusinessModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      handle: data['handle'] as String? ?? '',
      category: data['category'] as String? ?? '',
      active: data['active'] == true,
      coverage: data['coverage'] as String? ?? 'local',
      cityIds: data['cityIds'] is List
          ? (data['cityIds'] as List).whereType<String>().toList()
          : const [],
      mainCityId: data['mainCityId'] as String? ?? '',
      branchCount: (data['branchCount'] as num?)?.toInt() ?? 0,
      hasOwnerAccount: data['hasOwnerAccount'] == true,
      modules: modules,
      email: data['email'] as String? ?? '',
      manager: rep is Map ? rep['manager'] as String? ?? '' : '',
      managerPhone: rep is Map ? rep['phoneNumber'] as String? ?? '' : '',
      profileImageUrl: image is Map ? image['url'] as String? : null,
      limitBranches: limits is Map ? (limits['branches'] as num?)?.toInt() : null,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  final String id;
  final String name;
  final String handle;
  final String category;
  final bool active;

  /// 'local' o 'national'.
  final String coverage;
  final List<String> cityIds;
  final String mainCityId;
  final int branchCount;
  final bool hasOwnerAccount;
  final List<BusinessModuleState> modules;
  final String email;
  final String manager;
  final String managerPhone;
  final String? profileImageUrl;
  final int? limitBranches;
  final DateTime? createdAt;

  bool get isNational => coverage == 'national';

  /// Dirección pública, o null si no tiene handle.
  String? get publicUrl => handle.isEmpty ? null : 'https://viewgo.ec/$handle';

  /// Módulos que el negocio tiene encendidos.
  List<BusinessModuleState> get enabledModules =>
      modules.where((m) => m.enabled).toList();

  List<String> get branchCityIds =>
      cityIds.where((id) => id != nationalCityId).toList();

  /// Ciudades con sucursal. "Ibarra", "Ibarra y 2 más" o "Todo el país".
  /// La ciudad del filtro, si el negocio la tiene, va primero.
  String cityLabel(List<CityModel> cities, {String? preferredCityId}) {
    if (isNational) return 'Todo el país';
    final ids = branchCityIds;
    if (ids.isEmpty) return 'Sin ciudad';
    final first = (preferredCityId != null && ids.contains(preferredCityId))
        ? preferredCityId
        : (ids.contains(mainCityId) ? mainCityId : ids.first);
    final name = cities.byId(first)?.name ?? 'Ciudad';
    final others = ids.length - 1;
    return others > 0 ? '$name y $others más' : name;
  }

  /// Datos pendientes que el panel web también marca como alerta.
  bool get missingBranch => branchCount == 0;
}

/// Sucursal: `business/{id}/branches/{branchId}`.
class BranchModel {
  const BranchModel({
    required this.id,
    required this.label,
    required this.cityId,
    required this.address,
    required this.isMain,
    required this.active,
  });

  factory BranchModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    final address = data['address'];
    return BranchModel(
      id: doc.id,
      label: data['label'] as String? ?? '',
      cityId: data['cityId'] as String? ?? '',
      address: address is Map ? address['line'] as String? ?? '' : '',
      isMain: data['isMain'] == true,
      active: data['active'] != false,
    );
  }

  final String id;
  final String label;
  final String cityId;
  final String address;
  final bool isMain;
  final bool active;
}
