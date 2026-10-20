import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/liquid_glass.dart';
import '../../../../shared/widgets/reset_code_dialog.dart';
import '../../../tanda_creator/data/models/tanda_model.dart';
import '../../../tanda_creator/presentation/controllers/tanda_controller.dart';
import '../../../tanda_detail/presentation/screens/tanda_detail_screen.dart';
import '../../data/admin_repository.dart';

const _statusLabels = {
  'draft': 'Reclutando',
  'recruiting': 'Reclutando',
  'active': 'Activa',
  'completed': 'Terminada',
  'cancelled': 'Cancelada',
};

/// Panel del super admin: ve todas las tandas y corrige datos de cualquier persona.
/// En las tandas tiene los mismos permisos que el organizador.
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Administración'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          bottom: const TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.darkTextSecondary,
            tabs: [
              Tab(text: 'Tandas'),
              Tab(text: 'Personas'),
            ],
          ),
        ),
        body: const LiquidGlassBackground(
          child: SafeArea(
            child: TabBarView(
              children: [
                _AllTandasTab(),
                _UsersTab(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AllTandasTab extends ConsumerWidget {
  const _AllTandasTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tandas = ref.watch(allTandasProvider);
    final currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: '\$');

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        ref.invalidate(allTandasProvider);
        await ref.read(allTandasProvider.future).catchError((_) => <TandaModel>[]);
      },
      child: tandas.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => ListView(
          padding: const EdgeInsets.all(24),
          children: [Text(e.toString().replaceAll('Exception: ', ''), textAlign: TextAlign.center)],
        ),
        data: (list) {
          if (list.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(24),
              children: const [Text('Todavía no hay tandas en la app.', textAlign: TextAlign.center)],
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final tanda = list[index];
              return Material(
                color: AppColors.darkSurface,
                borderRadius: BorderRadius.circular(14),
                child: ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  title: Text(tanda.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    '${_statusLabels[tanda.status] ?? tanda.status} · '
                    'Organiza ${tanda.organizerName ?? '—'} · '
                    '${tanda.totalSlots} números de ${currencyFormat.format(tanda.contributionAmount)}',
                    style: const TextStyle(fontSize: 12, color: AppColors.darkTextSecondary),
                  ),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => TandaDetailScreen(tandaId: tanda.id)),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Buscador de personas reutilizable: con [onPick] devuelve a quien se toque
class UserSearchList extends ConsumerStatefulWidget {
  final void Function(Map<String, dynamic> user) onPick;

  const UserSearchList({super.key, required this.onPick});

  @override
  ConsumerState<UserSearchList> createState() => _UserSearchListState();
}

class _UserSearchListState extends ConsumerState<UserSearchList> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> _results = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await ref.read(adminRepositoryProvider).searchUsers(query);
      if (mounted && query == _controller.text) setState(() => _results = results);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void refresh() => _search(_controller.text);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Buscar por nombre, teléfono o correo',
              prefixIcon: const Icon(Icons.person_outline, color: AppColors.primary),
              filled: true,
              fillColor: AppColors.darkSurface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onChanged: (value) {
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 350), () => _search(value));
            },
          ),
        ),
        if (_loading) const LinearProgressIndicator(minHeight: 2, color: AppColors.primary),
        Expanded(
          child: _error != null
              ? Center(child: Text(_error!, textAlign: TextAlign.center))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final user = _results[index];
                    final email = user['email'] as String?;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                        child: Text(
                          (user['full_name'] as String).isNotEmpty
                              ? (user['full_name'] as String)[0].toUpperCase()
                              : '?',
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(user['full_name'] as String),
                      subtitle: Text(
                        email == null ? user['phone'] as String : '${user['phone']} · $email',
                        style: const TextStyle(fontSize: 12, color: AppColors.darkTextSecondary),
                      ),
                      onTap: () => widget.onPick(user),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// Para meter a alguien en un número: regresa la persona elegida o null
Future<Map<String, dynamic>?> showUserPicker(BuildContext context) {
  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.darkSurface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (sheetContext) => SizedBox(
      height: MediaQuery.of(sheetContext).size.height * 0.8,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Text('¿A quién le das este número?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ),
          Expanded(child: UserSearchList(onPick: (user) => Navigator.pop(sheetContext, user))),
        ],
      ),
    ),
  );
}

class _UsersTab extends StatefulWidget {
  const _UsersTab();

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  final _listKey = GlobalKey<_UserSearchListState>();

  @override
  Widget build(BuildContext context) {
    return UserSearchList(
      key: _listKey,
      onPick: (user) async {
        final saved = await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          backgroundColor: AppColors.darkSurface,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (_) => _EditUserSheet(user: user),
        );
        if (saved == true) _listKey.currentState?.refresh();
      },
    );
  }
}

class _EditUserSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> user;

  const _EditUserSheet({required this.user});

  @override
  ConsumerState<_EditUserSheet> createState() => _EditUserSheetState();
}

class _EditUserSheetState extends ConsumerState<_EditUserSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.user['full_name'] as String? ?? '');
  late final _phone = TextEditingController(text: widget.user['phone'] as String? ?? '');
  late final _email = TextEditingController(text: widget.user['email'] as String? ?? '');
  late final _clabe = TextEditingController(text: widget.user['clabe'] as String? ?? '');
  late final _bank = TextEditingController(text: widget.user['bank_name'] as String? ?? '');
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_name, _phone, _email, _clabe, _bank]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _emptyToNull(String value) => value.trim().isEmpty ? null : value.trim();

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref.read(adminRepositoryProvider).updateUser(widget.user['id'] as String, {
        'full_name': _name.text.trim(),
        'phone': _phone.text.trim(),
        'email': _emptyToNull(_email.text),
        'clabe': _emptyToNull(_clabe.text),
        'bank_name': _emptyToNull(_bank.text),
      });
      navigator.pop(true);
      messenger.showSnackBar(
        const SnackBar(content: Text('Datos guardados ✅'), backgroundColor: AppColors.primaryDark),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppColors.error),
      );
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _resetCode() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final code = await ref.read(adminRepositoryProvider).createResetCode(widget.user['id'] as String);
      if (!mounted) return;
      await showResetCodeDialog(context, code: code, userName: widget.user['full_name'] as String);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppColors.error),
      );
    }
  }

  InputDecoration _decoration(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.darkCard,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Corregir datos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text(
                'El teléfono es con lo que entra a la app.',
                style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 12),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: _decoration('Nombre completo'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Escribe el nombre' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: _decoration('Teléfono (10 dígitos)'),
                validator: (v) => RegExp(r'^\d{10}$').hasMatch(v?.trim() ?? '') ? null : 'Deben ser 10 dígitos',
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: _decoration('Correo (opcional)'),
                validator: (v) {
                  final value = v?.trim() ?? '';
                  return value.isEmpty || RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)
                      ? null
                      : 'Correo no válido';
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _clabe,
                keyboardType: TextInputType.number,
                decoration: _decoration('CLABE (opcional)'),
                validator: (v) {
                  final value = v?.trim() ?? '';
                  return value.isEmpty || RegExp(r'^\d{18}$').hasMatch(value) ? null : 'La CLABE tiene 18 dígitos';
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _bank,
                textCapitalization: TextCapitalization.words,
                decoration: _decoration('Banco (opcional)'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.darkBg),
                      )
                    : const Text('Guardar', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                icon: const Icon(Icons.key_outlined, size: 18),
                label: const Text('Código para cambiar su contraseña'),
                onPressed: _saving ? null : _resetCode,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
