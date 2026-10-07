import 'package:flutter_test/flutter_test.dart';
import 'package:propertydilado_mobile/core/indian_currency_formatter.dart';

void main() {
  group('IndianCurrencyFormatter Tests', () {
    test('converts numbers to Indian words accurately', () {
      expect(IndianCurrencyFormatter.toWords(0), '');
      expect(IndianCurrencyFormatter.toWords(500), 'Five Hundred');
      expect(IndianCurrencyFormatter.toWords(25000), 'Twenty Five Thousand');
      expect(IndianCurrencyFormatter.toWords(500000), 'Five Lakh');
      expect(IndianCurrencyFormatter.toWords(7500000), 'Seventy Five Lakh');
      expect(IndianCurrencyFormatter.toWords(15000000), 'One Crore Fifty Lakh');
      expect(IndianCurrencyFormatter.toWords(200000000), 'Twenty Crore');
    });

    test('formats short Indian currency representations', () {
      expect(IndianCurrencyFormatter.toShortIndian(25000), '₹ 25 K');
      expect(IndianCurrencyFormatter.toShortIndian(5000000), '₹ 50 Lac');
      expect(IndianCurrencyFormatter.toShortIndian(15000000), '₹ 1.50 Cr');
      expect(IndianCurrencyFormatter.toShortIndian(20000000), '₹ 2 Cr');
    });
  });
}
