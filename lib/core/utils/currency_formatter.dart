import 'package:intl/intl.dart';

class CurrencyFormatter {
  // Format cents to currency string (e.g., 50000 -> "$500.00")
  static String formatCents(int? cents) {
    if (cents == null) return 'N/A';
    final dollars = cents / 100;
    return NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(dollars);
  }

  // Parse currency string to cents (e.g., "500" -> 50000)
  static int? parseToCents(String value) {
    if (value.isEmpty) return null;
    final cleanValue = value.replaceAll(RegExp(r'[^\d.]'), '');
    final double? dollars = double.tryParse(cleanValue);
    if (dollars == null) return null;
    return (dollars * 100).round();
  }

  // Format for display in input (e.g., 50000 -> "500.00")
  static String formatForInput(int? cents) {
    if (cents == null) return '';
    final dollars = cents / 100;
    return dollars.toStringAsFixed(2);
  }
}

class DateFormatter {
  // Format date for display (e.g., "Mar 1, 2026")
  static String formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('MMM d, y').format(date);
  }

  // Format date for API (ISO 8601)
  static String formatForApi(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
}