import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_colors.dart';

/// Muestra el código para cambiar contraseña y permite mandarlo por WhatsApp
Future<void> showResetCodeDialog(BuildContext context, {required String code, required String userName}) {
  final firstName = userName.split(' ').first;
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Código para $firstName'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SelectableText(
            code,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Dura 30 minutos y sirve una sola vez. Con él, en el login, toca '
            '"¿Olvidaste tu contraseña?" y escribe una nueva.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 13),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cerrar'),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.share_outlined, size: 18),
          label: const Text('Enviar'),
          onPressed: () {
            Navigator.pop(dialogContext);
            SharePlus.instance.share(ShareParams(
              text: 'Tu código para cambiar tu contraseña en Tanditas es: $code (dura 30 minutos). '
                  'En el login toca "¿Olvidaste tu contraseña?".',
            ));
          },
        ),
      ],
    ),
  );
}
