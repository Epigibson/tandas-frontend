import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/brand_config.dart';
import '../controllers/tanda_controller.dart';

class CreateTandaScreen extends ConsumerStatefulWidget {
  const CreateTandaScreen({super.key});

  @override
  ConsumerState<CreateTandaScreen> createState() => _CreateTandaScreenState();
}

class _CreateTandaScreenState extends ConsumerState<CreateTandaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController(text: 'Tanda Familiar 2026');
  final _descriptionController = TextEditingController(text: 'Ahorro para vacaciones y regalos');
  final _customAmountController = TextEditingController();

  double _selectedAmount = 200.0;
  int _totalSlots = 10;
  String _selectedFrequency = 'quincenal';
  String _selectedAssignment = 'draw';
  bool _isLoading = false;

  final List<double> _quickAmounts = [200.0, 300.0, 500.0, 1000.0, 1500.0, 2000.0];

  final Map<String, String> _frequencyLabels = {
    'semanal': 'Semanal (7 días)',
    'catorcenal': 'Catorcenal (14 días)',
    'quincenal': 'Quincenal (Días 15 y 30)',
    'mensual': 'Mensual (30 días)',
  };

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _customAmountController.dispose();
    super.dispose();
  }

  double get _totalPot => _selectedAmount * _totalSlots;

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();

    try {
      final tanda = await ref.read(tandaCreatorControllerProvider.notifier).createTanda(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            contributionAmount: _selectedAmount,
            totalSlots: _totalSlots,
            frequency: _selectedFrequency,
            assignmentMethod: _selectedAssignment,
          );

      if (mounted) {
        _showSuccessDialog(tanda.title, tanda.inviteCode, _totalPot);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessDialog(String title, String inviteCode, double pot) {
    final currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: '\$');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.darkSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Center(
            child: Icon(Icons.celebration_outlined, color: AppColors.primary, size: 50),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '¡Tanda Creada con Éxito!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Bolsa total: ${currencyFormat.format(pot)} MXN',
                style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Código de Invitación:',
                      style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      inviteCode,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Comparte este código en tu grupo de WhatsApp familiar para que elijan su número.',
                style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.share_outlined),
                label: const Text('Copiar Mensaje para WhatsApp'),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  final msg =
                      '¡Hola familia! Cree la tanda "$title" con bolsa de ${currencyFormat.format(pot)} MXN. Únanse en la app con el código: $inviteCode 📱🎉';
                  Clipboard.setData(ClipboardData(text: msg));
                  Navigator.pop(context); // Cierra diálogo
                  Navigator.pop(context); // Regresa al Home
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Mensaje copiado. ¡Pégalo en tu WhatsApp! 💬'),
                      backgroundColor: AppColors.primaryDark,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: '\$');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Tanda'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Tarjeta Resumen en Vivo del Pozo
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: BrandConfig.createSummaryGradient,
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bolsa Total a Repartir',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currencyFormat.format(_totalPot),
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: AppColors.gold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$_totalSlots turnos',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Nombre de la Tanda
                TextFormField(
                  controller: _titleController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: 'Nombre de la Tanda',
                    hintText: 'ej. Tanda Navideña Familia Pérez',
                    prefixIcon: const Icon(Icons.stars_outlined, color: AppColors.primary),
                    filled: true,
                    fillColor: AppColors.darkSurface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.darkBorder),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Por favor escribe un nombre';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Objetivo o Descripción
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Objetivo (Opcional)',
                    hintText: 'ej. Regalos de fin de año y vacaciones',
                    prefixIcon: const Icon(Icons.flag_outlined, color: AppColors.primary),
                    filled: true,
                    fillColor: AppColors.darkSurface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.darkBorder),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Selector de Cuota Periódica
                const Text(
                  'Aportación por persona en cada turno',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: _quickAmounts.map((amt) {
                    final isSelected = _selectedAmount == amt;
                    return ChoiceChip(
                      label: Text(currencyFormat.format(amt)),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? AppColors.darkBg : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      backgroundColor: AppColors.darkSurface,
                      onSelected: (val) {
                        if (val) {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedAmount = amt);
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _customAmountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'O escribe otro monto',
                    hintText: 'Mínimo \$200 MXN',
                    prefixText: '\$ ',
                    prefixStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                    filled: true,
                    fillColor: AppColors.darkSurface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.darkBorder),
                    ),
                  ),
                  onChanged: (val) {
                    final parsed = double.tryParse(val.replaceAll(RegExp(r'[^0-9.]'), ''));
                    if (parsed != null && parsed >= 200) {
                      setState(() => _selectedAmount = parsed);
                    }
                  },
                ),
                const SizedBox(height: 24),

                // Número de Turnos (Participantes)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Número de turnos / participantes:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      '$_totalSlots números',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _totalSlots.toDouble(),
                  min: 4,
                  max: 20,
                  divisions: 16,
                  activeColor: AppColors.primary,
                  inactiveColor: AppColors.darkBorder,
                  label: '$_totalSlots',
                  onChanged: (val) {
                    HapticFeedback.selectionClick();
                    setState(() => _totalSlots = val.toInt());
                  },
                ),
                const SizedBox(height: 16),

                // Frecuencia
                const Text(
                  'Frecuencia de las aportaciones',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.darkSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.darkBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedFrequency,
                      isExpanded: true,
                      dropdownColor: AppColors.darkSurface,
                      items: _frequencyLabels.entries.map((entry) {
                        return DropdownMenuItem<String>(
                          value: entry.key,
                          child: Text(entry.value),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedFrequency = val);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Método de Asignación de Números
                const Text(
                  '¿Cómo se asignarán los números?',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 10),
                _buildAssignmentOption(
                  id: 'draw',
                  title: '🎲 Sorteo Digital Aleatorio',
                  subtitle: 'La app sortea los números de forma transparente y justa.',
                ),
                const SizedBox(height: 8),
                _buildAssignmentOption(
                  id: 'first_come',
                  title: '⚡ Elección Libre',
                  subtitle: 'Cada quien escoge su número disponible al unirse.',
                ),
                const SizedBox(height: 32),

                // Botón Crear
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleCreate,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.darkBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.darkBg,
                          ),
                        )
                      : const Text(
                          'Crear Tanda Familiar 🎉',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAssignmentOption({
    required String id,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _selectedAssignment == id;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedAssignment = id);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.darkSurface : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.darkBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.primary : AppColors.darkTextSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
