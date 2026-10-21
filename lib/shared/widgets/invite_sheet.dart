import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/invite_link.dart';

/// QR + enlace + código. El QR se escanea con la cámara normal del teléfono y abre el enlace.
Future<void> showInviteSheet(
  BuildContext context, {
  required String title,
  required String inviteCode,
  String? potText,
}) {
  final link = inviteLink(inviteCode);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.darkSurface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Invitar a la tanda',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Que escaneen el código con la cámara de su teléfono, o mándales el enlace.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 12),
            ),
            const SizedBox(height: 16),
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: QrImageView(
                  data: link,
                  size: 210,
                  backgroundColor: Colors.white,
                  semanticsLabel: 'Código QR para unirse a la tanda',
                ),
              ),
            ),
            const SizedBox(height: 14),
            SelectableText(
              inviteCode,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.share_outlined, size: 18),
              label: const Text('Mandar invitación'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: () {
                HapticFeedback.selectionClick();
                SharePlus.instance.share(ShareParams(
                  text: inviteMessage(title: title, inviteCode: inviteCode, potText: potText),
                  subject: 'Invitación a la tanda "$title"',
                ));
              },
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: link));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enlace copiado'), backgroundColor: AppColors.primaryDark),
                );
              },
              child: const Text('Copiar enlace'),
            ),
          ],
        ),
      ),
    ),
  );
}
