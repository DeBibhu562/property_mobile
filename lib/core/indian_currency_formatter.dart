/// Helper utility to format numbers into standard Indian numbering system
/// and convert amounts into English words (Lakhs, Crores, Thousands).
class IndianCurrencyFormatter {
  static const List<String> _units = [
    '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine',
    'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen',
    'Seventeen', 'Eighteen', 'Nineteen'
  ];

  static const List<String> _tens = [
    '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'
  ];

  /// Formats an integer into Indian comma grouping (e.g. 1,00,00,000)
  static String formatComma(num amount) {
    final str = amount.toInt().toString();
    if (str.length <= 3) return str;

    final lastThree = str.substring(str.length - 3);
    var remaining = str.substring(0, str.length - 3);
    final buffer = StringBuffer();

    while (remaining.length > 2) {
      final part = remaining.substring(remaining.length - 2);
      buffer.write(',$part');
      remaining = remaining.substring(0, remaining.length - 2);
    }

    return '$remaining$buffer,$lastThree';
  }

  /// Converts a number to human-readable Indian words (e.g. "Forty Five Lakh")
  static String toWords(num? value) {
    if (value == null || value <= 0) return '';
    final n = value.toInt();
    if (n == 0) return 'Zero';

    return _convertNumber(n).trim();
  }

  /// Short representation (e.g. ₹ 45 Lac or ₹ 1.25 Cr)
  static String toShortIndian(num? value) {
    if (value == null || value <= 0) return '₹ 0';
    final n = value.toDouble();

    if (n >= 10000000) {
      final cr = n / 10000000;
      return '₹ ${cr.toStringAsFixed(cr.truncateToDouble() == cr ? 0 : 2)} Cr';
    } else if (n >= 100000) {
      final lac = n / 100000;
      return '₹ ${lac.toStringAsFixed(lac.truncateToDouble() == lac ? 0 : 2)} Lac';
    } else if (n >= 1000) {
      final k = n / 1000;
      return '₹ ${k.toStringAsFixed(k.truncateToDouble() == k ? 0 : 1)} K';
    } else {
      return '₹ ${n.toInt()}';
    }
  }

  static String _convertNumber(int n) {
    if (n < 20) {
      return _units[n];
    }
    if (n < 100) {
      return '${_tens[n ~/ 10]} ${_units[n % 10]}'.trim();
    }
    if (n < 1000) {
      return '${_units[n ~/ 100]} Hundred ${_convertNumber(n % 100)}'.trim();
    }
    if (n < 100000) {
      return '${_convertNumber(n ~/ 1000)} Thousand ${_convertNumber(n % 1000)}'.trim();
    }
    if (n < 10000000) {
      return '${_convertNumber(n ~/ 100000)} Lakh ${_convertNumber(n % 100000)}'.trim();
    }
    return '${_convertNumber(n ~/ 10000000)} Crore ${_convertNumber(n % 10000000)}'.trim();
  }
}
