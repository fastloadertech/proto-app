/// The shared Prisma schema stores INR Decimal(12,2). Proto keeps integer
/// paise at the wire boundary to avoid binary floating-point rounding.
class MoneyCodec {
  const MoneyCodec._();

  static int paiseFromRupees(Object value) {
    final text = value.toString();
    final match = RegExp(r'^(\d+)(?:\.(\d{1,2}))?$').firstMatch(text);
    if (match == null) throw FormatException('Invalid INR amount: $text');
    final rupees = int.parse(match.group(1)!);
    final fraction = (match.group(2) ?? '').padRight(2, '0');
    return rupees * 100 + (fraction.isEmpty ? 0 : int.parse(fraction));
  }

  static String rupeesFromPaise(int paise) {
    if (paise < 0) throw ArgumentError.value(paise, 'paise');
    return '${paise ~/ 100}.${(paise % 100).toString().padLeft(2, '0')}';
  }
}
