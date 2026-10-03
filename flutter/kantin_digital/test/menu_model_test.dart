import 'package:flutter_test/flutter_test.dart';
import 'package:kantin_digital/shared/models/menu_model.dart';

void main() {
  group('MenuModel sequenceNumber & flyerOrder tests', () {
    test('Matches Coffee flyer items correctly', () {
      const m1 = MenuModel(id: 1, name: 'SAY AREN', categoryName: 'Kopi', price: 15000);
      const m2 = MenuModel(id: 2, name: 'SAY BUTTER BLISS', categoryName: 'Kopi', price: 15000);
      const m3 = MenuModel(id: 3, name: 'SAY HAZEL HUG', categoryName: 'Kopi', price: 15000);
      const m4 = MenuModel(id: 4, name: 'SAY MILKY BREW', categoryName: 'Kopi', price: 15000);
      const m5 = MenuModel(id: 5, name: 'SAY SWEET CREAM', categoryName: 'Kopi', price: 18000);
      const m6 = MenuModel(id: 6, name: 'SAY BLACK BREW', categoryName: 'Kopi', price: 12000);

      expect(m1.sequenceNumber, '01');
      expect(m2.sequenceNumber, '02');
      expect(m3.sequenceNumber, '03');
      expect(m4.sequenceNumber, '04');
      expect(m5.sequenceNumber, '05');
      expect(m6.sequenceNumber, '06');

      expect(m1.flyerOrder, 1);
      expect(m2.flyerOrder, 2);
      expect(m3.flyerOrder, 3);
      expect(m4.flyerOrder, 4);
      expect(m5.flyerOrder, 5);
      expect(m6.flyerOrder, 6);
    });

    test('Matches Non-Coffee flyer items correctly', () {
      const n1 = MenuModel(id: 7, name: 'SAY MATCHA MOOD', categoryName: 'Non Kopi', price: 15000);
      const n2 = MenuModel(id: 8, name: 'SAY CHOCO STORY', categoryName: 'Non Kopi', price: 18000);
      const n3 = MenuModel(id: 9, name: 'SAY CHOCO HAZEL', categoryName: 'Non Kopi', price: 18000);

      expect(n1.sequenceNumber, '01');
      expect(n2.sequenceNumber, '02');
      expect(n3.sequenceNumber, '03');

      expect(n1.flyerOrder, 7);
      expect(n2.flyerOrder, 8);
      expect(n3.flyerOrder, 9);
    });

    test('Correctly sorts mixed list according to flyer sequence', () {
      final list = [
        const MenuModel(id: 9, name: 'SAY CHOCO HAZEL', categoryName: 'Non Kopi', price: 18000),
        const MenuModel(id: 6, name: 'SAY BLACK BREW', categoryName: 'Kopi', price: 12000),
        const MenuModel(id: 1, name: 'SAY AREN', categoryName: 'Kopi', price: 15000),
        const MenuModel(id: 7, name: 'SAY MATCHA MOOD', categoryName: 'Non Kopi', price: 15000),
      ];

      list.sort((a, b) => a.flyerOrder.compareTo(b.flyerOrder));

      expect(list.map((e) => e.name).toList(), [
        'SAY AREN',
        'SAY BLACK BREW',
        'SAY MATCHA MOOD',
        'SAY CHOCO HAZEL',
      ]);
    });

    test('Correctly formats code with prefix and database code', () {
      const m = MenuModel(id: 1, code: '01', name: 'SAY AREN', categoryName: 'Kopi', price: 15000);
      expect(m.formattedCode('SAY'), 'SAY-01');
      expect(m.formattedCode('CAFE'), 'CAFE-01');

      // Test with custom prefix in code already
      const mCustom = MenuModel(id: 2, code: 'SAY-02', name: 'SAY BUTTER BLISS', categoryName: 'Kopi', price: 15000);
      expect(mCustom.formattedCode('SAY'), 'SAY-02');

      // Test fallback to sequenceNumber if code is null
      const mFallback = MenuModel(id: 3, name: 'SAY HAZEL HUG', categoryName: 'Kopi', price: 15000);
      expect(mFallback.formattedCode('SAY'), 'SAY-03');
    });
  });
}
