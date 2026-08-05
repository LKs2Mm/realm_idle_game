String formatXp(num value) {
  final decimal = value.toDouble();
  if (!decimal.isFinite) return '0';

  final rounded = (decimal * 10).roundToDouble() / 10;
  final text = rounded == rounded.truncateToDouble()
      ? rounded.toStringAsFixed(0)
      : rounded.toStringAsFixed(1);
  return text.replaceAll('.', ',');
}

String formatInteger(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write('.');
    buffer.write(digits[index]);
  }
  return value < 0 ? '-$buffer' : buffer.toString();
}
