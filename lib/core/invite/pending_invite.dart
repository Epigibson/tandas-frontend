import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/invite_link.dart';

/// Código que llegó en el enlace (`?unirse=CODIGO`). Se guarda mientras la persona entra o
/// crea su cuenta, y el Home abre la pantalla para elegir número en cuanto hay sesión.
class PendingInvite extends Notifier<String?> {
  @override
  String? build() {
    if (!kIsWeb) return null;
    final code = Uri.base.queryParameters['unirse'];
    return (code == null || code.trim().isEmpty) ? null : extractInviteCode(code);
  }

  void clear() => state = null;
}

final pendingInviteProvider = NotifierProvider<PendingInvite, String?>(PendingInvite.new);
