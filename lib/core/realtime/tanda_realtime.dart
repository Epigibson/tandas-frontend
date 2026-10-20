import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:realtime_client/realtime_client.dart';
import '../../features/tanda_creator/presentation/controllers/tanda_controller.dart';
import '../../features/tanda_detail/presentation/controllers/tanda_detail_controller.dart';

/// Llave pública de Supabase: está hecha para ir en la app. Con RLS activo no da acceso
/// a tablas ni al bucket privado; aquí solo se usa para escuchar avisos de Broadcast.
const _supabaseRealtimeUrl = 'wss://zpweeprqdlbbzbesvqrk.supabase.co/realtime/v1';
const _supabasePublishableKey = 'sb_publishable_qU0Flm0i10PEC3Wrbl7cGg_J3DyR88v';

/// Debe coincidir con `TANDA_CHANGED_EVENT` en backend/app/services/realtime_service.py
const _tandaChangedEvent = 'changed';

final realtimeClientProvider = Provider<RealtimeClient>((ref) {
  final client = RealtimeClient(
    _supabaseRealtimeUrl,
    params: {'apikey': _supabasePublishableKey},
    // Sin tandas en pantalla (p. ej. en el login) no tiene caso mantener el socket abierto
    disconnectOnEmptyChannelsAfter: const Duration(seconds: 30),
  );
  ref.onDispose(client.disconnect);
  return client;
});

/// Mantiene la suscripción al canal `tanda:{id}` mientras alguna pantalla la observe.
/// El aviso no trae datos: solo dispara que se vuelvan a pedir al backend.
final tandaRealtimeProvider = Provider.autoDispose.family<void, String>((ref, tandaId) {
  final client = ref.watch(realtimeClientProvider);
  Timer? debounce;

  final channel = client.channel('tanda:$tandaId').onBroadcast(
    event: _tandaChangedEvent,
    callback: (_) {
      // Una acción puede generar varios avisos seguidos: se agrupan en una sola recarga
      debounce?.cancel();
      debounce = Timer(const Duration(milliseconds: 400), () {
        ref.invalidate(tandaDetailProvider(tandaId));
        ref.invalidate(tandaPaymentsProvider(tandaId));
        ref.invalidate(myTandasProvider);
      });
    },
  ).subscribe();

  ref.onDispose(() {
    debounce?.cancel();
    client.removeChannel(channel);
  });
});
