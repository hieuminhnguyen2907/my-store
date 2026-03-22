String formatVnd(num value) {
  final rounded = value.round();
  final isNegative = rounded < 0;
  final digits = rounded.abs().toString();
  final buffer = StringBuffer();

  for (var index = 0; index < digits.length; index++) {
    final reverseIndex = digits.length - index;
    buffer.write(digits[index]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write('.');
    }
  }

  final formatted = '${isNegative ? '-' : ''}${buffer.toString()}';
  return '$formatted đ';
}
