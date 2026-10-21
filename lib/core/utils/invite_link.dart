/// La versión web abre la pantalla para elegir número cuando trae `?unirse=CODIGO`.
/// Sirve en iPhone y en Android sin instalar nada.
const inviteBaseUrl = 'https://tanditas.vercel.app';

String inviteLink(String inviteCode) => '$inviteBaseUrl/?unirse=${Uri.encodeQueryComponent(inviteCode)}';

/// Acepta el código suelto o el enlace completo que llegó por WhatsApp
String extractInviteCode(String input) {
  final text = input.trim();
  final match = RegExp(r'unirse=([A-Za-z0-9\-]+)').firstMatch(text);
  return (match?.group(1) ?? text).toUpperCase();
}

/// Mensaje para compartir: el enlace para quien no tiene la app y el código para quien sí
String inviteMessage({required String title, required String inviteCode, String? potText}) {
  final pot = potText == null ? '' : ' con bolsa de $potText';
  return '¡Hola! Te invito a la tanda "$title"$pot 🎉\n\n'
      'Entra aquí para elegir tu número: ${inviteLink(inviteCode)}\n\n'
      'Si ya tienes la app Tanditas, toca "Unirme" y pega este código: $inviteCode';
}
