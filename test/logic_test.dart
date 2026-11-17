import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saviewgo/features/alerts/admin_notification.dart';
import 'package:saviewgo/features/businesses/business_model.dart';
import 'package:saviewgo/features/businesses/businesses_repository.dart';
import 'package:saviewgo/features/cities/city_model.dart';
import 'package:saviewgo/features/orders/order_audit.dart';
import 'package:saviewgo/features/transfers/transfer_item.dart';
import 'package:saviewgo/shared/models/business_module.dart';
import 'package:saviewgo/shared/utils/input_rules.dart';
import 'package:saviewgo/shared/utils/text_normalize.dart';

/// Aplica una lista de formateadores como si la persona hubiera escrito
/// (o pegado) [text] en un campo vacío.
String typed(List<TextInputFormatter> formatters, String text) {
  var current = TextEditingValue(
    text: text,
    selection: TextSelection.collapsed(offset: text.length),
  );
  // Cada formateador recibe el resultado del anterior, como en un campo.
  for (final f in formatters) {
    current = f.formatEditUpdate(TextEditingValue.empty, current);
  }
  return current.text;
}

void main() {
  group('Entrada de datos', () {
    test('normalizeText quita tildes, mayúsculas y signos', () {
      expect(normalizeText('  Café   Andino! '), 'cafe andino');
    });

    test('cleanText recorta y junta espacios', () {
      expect(cleanText('  hola   mundo  '), 'hola mundo');
    });

    test('cleanReason descarta símbolos de código', () {
      expect(cleanReason('  monto <b>no</b>; coincide  '), 'monto bno/b coincide');
      expect(cleanReason(r'a${x}`b'), 'axb');
    });

    test('nameInputFormatters: sin símbolos, sin espacios al inicio ni seguidos', () {
      final f = nameInputFormatters(maxLength: 40);
      expect(typed(f, '  Café   <Andino>'), 'Café Andino');
      expect(typed(f, "Pan & Café, S.A. 24/7"), 'Pan & Café, S.A. 24/7');
    });

    test('nameInputFormatters: respeta el largo máximo al pegar', () {
      final f = nameInputFormatters(maxLength: 10);
      expect(typed(f, 'a' * 100).length, 10);
    });

    test('reasonInputFormatters: sin saltos de línea ni símbolos', () {
      final f = reasonInputFormatters(maxLength: 200);
      expect(typed(f, 'línea uno\nlínea {dos}'), 'línea unolínea dos');
      expect(typed(f, 'x' * 500).length, 200);
    });
  });

  group('Negocios', () {
    test('BusinessFilters: copyWith distingue "sin cambio" de "quitar"', () {
      const base = BusinessFilters(active: true, module: BusinessModule.food);
      expect(base.copyWith(query: 'ab').active, true);
      expect(base.copyWith(active: null).active, isNull);
      expect(base.copyWith(module: null).module, isNull);
      expect(base.copyWith(), base);
    });

    test('BusinessFilters: solo busca con texto que normaliza a algo', () {
      expect(const BusinessFilters(query: '  ').isSearching, false);
      expect(const BusinessFilters(query: '!!').isSearching, false);
      expect(const BusinessFilters(query: 'café').isSearching, true);
    });

    test('cityLabel: nacional, una ciudad, varias y con ciudad preferida', () {
      const quito = CityModel(
        id: 'q', key: 'q', name: 'Quito', slug: 'quito', province: 'P', active: true);
      const ibarra = CityModel(
        id: 'i', key: 'i', name: 'Ibarra', slug: 'ibarra', province: 'P', active: true);
      BusinessModel business(String coverage, List<String> ids, String main) => BusinessModel(
            id: 'b',
            name: 'N',
            handle: 'n',
            category: 'food_drink',
            active: true,
            coverage: coverage,
            cityIds: ids,
            mainCityId: main,
            branchCount: ids.length,
            hasOwnerAccount: true,
            modules: const [],
          );

      const cities = [quito, ibarra];
      expect(business('national', ['_national'], '').cityLabel(cities), 'Todo el país');
      expect(business('local', ['q'], 'q').cityLabel(cities), 'Quito');
      expect(business('local', ['q', 'i'], 'q').cityLabel(cities), 'Quito y 1 más');
      expect(
        business('local', ['q', 'i'], 'q').cityLabel(cities, preferredCityId: 'i'),
        'Ibarra y 1 más',
      );
      expect(business('local', [], '').cityLabel(cities), 'Sin ciudad');
      expect(business('local', [], '').missingBranch, true);
    });
  });

  group('Alertas', () {
    AdminNotification n(List<String> readBy) => AdminNotification(
          id: '1',
          title: 't',
          body: 'b',
          module: 'food',
          orderId: 'o',
          status: 's',
          cityId: 'c',
          readBy: readBy,
          createdAt: DateTime(2026),
        );

    test('markedReadBy agrega el uid una sola vez', () {
      final once = n(['a']).markedReadBy('b');
      expect(once.readBy, ['a', 'b']);
      expect(once.markedReadBy('b').readBy, ['a', 'b']);
      expect(once.isReadBy('b'), true);
      expect(n(const []).isReadBy('b'), false);
    });
  });

  group('Transferencias', () {
    TransferItem item(TransferKind kind, String id) => TransferItem(
          kind: kind,
          id: id,
          title: 't',
          subtitle: '',
          amount: 1,
          cityId: 'c',
          createdAt: null,
          canResolve: true,
          lines: const [],
          confirmText: '',
        );

    test('un pago es el mismo si coinciden flujo e id', () {
      expect(item(TransferKind.food, '1'), item(TransferKind.food, '1'));
      expect(item(TransferKind.food, '1') == item(TransferKind.ecommerce, '1'), false);
    });

    test('fromKey reconoce los cinco flujos y rechaza lo demás', () {
      for (final k in TransferKind.values) {
        expect(TransferKind.fromKey(k.key), k);
      }
      expect(TransferKind.fromKey('otro'), isNull);
      expect(TransferKind.fromKey(null), isNull);
    });
  });

  group('Pedidos', () {
    test('statusTone clasifica los estados del contrato', () {
      expect(statusTone('completed'), StatusTone.good);
      expect(statusTone('payment_rejected'), StatusTone.bad);
      expect(statusTone('payment_received'), StatusTone.warn);
      expect(statusTone('on_the_way'), StatusTone.neutral);
    });

    test('todo estado conocido tiene etiqueta en español', () {
      for (final status in orderStatusLabels.keys) {
        expect(statusLabel(status), isNot(status));
      }
      expect(statusLabel('desconocido'), 'desconocido');
    });
  });
}
