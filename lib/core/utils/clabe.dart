/// Valida el dígito verificador de una CLABE de 18 dígitos (pesos 3, 7, 1)
bool isValidClabe(String clabe) {
  if (!RegExp(r'^\d{18}$').hasMatch(clabe)) return false;
  const weights = [3, 7, 1];
  var sum = 0;
  for (var i = 0; i < 17; i++) {
    sum += (int.parse(clabe[i]) * weights[i % 3]) % 10;
  }
  final checkDigit = (10 - sum % 10) % 10;
  return checkDigit == int.parse(clabe[17]);
}

/// "012180001234567891" → "012 180 00123456789 1", más fácil de dictar y revisar
String formatClabe(String clabe) {
  if (clabe.length != 18) return clabe;
  return '${clabe.substring(0, 3)} ${clabe.substring(3, 6)} ${clabe.substring(6, 17)} ${clabe.substring(17)}';
}
