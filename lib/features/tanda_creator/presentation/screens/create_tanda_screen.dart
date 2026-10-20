import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/brand_config.dart';
import '../../../../shared/widgets/liquid_glass.dart';
import '../../data/models/tanda_model.dart';
import '../controllers/tanda_controller.dart';

class CreateTandaScreen extends ConsumerStatefulWidget {
  /// Con una tanda, la pantalla la edita en vez de crear una nueva (solo antes de iniciar)
  final TandaModel? tanda;

  const CreateTandaScreen({super.key, this.tanda});

  @override
  ConsumerState<CreateTandaScreen> createState() => _CreateTandaScreenState();
}

class _CreateTandaScreenState extends ConsumerState<CreateTandaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _customAmountController = TextEditingController();

  double _selectedAmount = 200.0;
  int _totalSlots = 10;
  String _selectedFrequency = 'quincenal';
  String _selectedAssignment = 'draw';
  late DateTime _startDate;
  bool _isLoading = false;

  bool get _isEditing => widget.tanda != null;

  final List<double> _quickAmounts = [200.0, 300.0, 500.0, 1000.0, 1500.0, 2000.0];

  final Map<String, String> _frequencyLabels = {
    'semanal': 'Semanal (7 días)',
    'catorcenal': 'Catorcenal (14 días)',
    'quincenal': 'Quincenal (días 15 y último de mes)',
    'mensual': 'Mensual (30 días)',
  };

  @override
  void initState() {
    super.initState();
    final today = DateUtils.dateOnly(DateTime.now());
    final tanda = widget.tanda;
    if (tanda == null) {
      _startDate = today;
      return;
    }
    _titleController.text = tanda.title;
    _descriptionController.text = tanda.description ?? '';
    _selectedAmount = tanda.contributionAmount;
    if (!_quickAmounts.contains(tanda.contributionAmount)) {
      _customAmountController.text = NumberFormat('0.##').format(tanda.contributionAmount);
    }
    _totalSlots = tanda.totalSlots.clamp(4, 20);
    _selectedFrequency = tanda.frequency;
    _selectedAssignment = tanda.assignmentMethod == 'first_come' ? 'first_come' : 'draw';
    final saved = tanda.startDate == null ? today : DateUtils.dateOnly(tanda.startDate!.toLocal());
    // Si la fecha pactada ya pasó, se propone hoy (el backend no acepta fechas pasadas)
    _startDate = saved.isBefore(today) ? today : saved;
  }

  Future<void> _pickStartDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      helpText: 'Fecha de inicio de la tanda',
    );
    if (picked != null) setState(() => _startDate = picked);
  }

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

    // Mediodía local: al pasar a UTC el día no cambia
    final startDate = DateTime(_startDate.year, _startDate.month, _startDate.day, 12);
    final controller = ref.read(tandaCreatorControllerProvider.notifier);
    try {
      if (_isEditing) {
        await controller.updateTanda(
          tandaId: widget.tanda!.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          contributionAmount: _selectedAmount,
          totalSlots: _totalSlots,
          frequency: _selectedFrequency,
          assignmentMethod: _selectedAssignment,
          startDate: startDate,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cambios guardados ✅'),
              backgroundColor: AppColors.primaryDark,
            ),
          );
          Navigator.pop(context, true);
        }
        return;
      }

      final tanda = await controller.createTanda(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            contributionAmount: _selectedAmount,
            totalSlots: _totalSlots,
            frequency: _selectedFrequency,
            assignmentMethod: _selectedAssignment,
            startDate: startDate,
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
                label: const Text('Compartir invitación'),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  final msg =
                      '¡Hola familia! Creé la tanda "$title" con bolsa de ${currencyFormat.format(pot)} MXN. Únanse en la app con el código: $inviteCode 📱🎉';
                  Navigator.pop(context); // Cierra diálogo
                  Navigator.pop(context); // Regresa al Home
                  SharePlus.instance.share(ShareParams(text: msg, subject: 'Invitación a la tanda "$title"'));
                },
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context); // Cierra diálogo
                  Navigator.pop(context); // Regresa al Home
                },
                child: const Text('Compartir después'),
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
        title: Text(_isEditing ? 'Editar tanda' : 'Nueva Tanda'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: LiquidGlassBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Tarjeta Resumen en Vivo del Pozo con Vidrio Líquido Esmeralda
                  LiquidGlassContainer(
                    padding: const EdgeInsets.all(22),
                    borderRadius: BrandConfig.cardRadius,
                    tintColor: AppColors.primary,
                    blur: 16,
                    opacity: 0.12,
                    borderOpacity: 0.3,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Con montos grandes o letra grande, la cifra se encoge en vez de desbordarse
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Bolsa Total a Repartir',
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  currencyFormat.format(_totalPot),
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.gold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black38,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
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
                          _customAmountController.clear();
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
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return null;
                    final parsed = double.tryParse(val.replaceAll(RegExp(r'[^0-9.]'), ''));
                    if (parsed == null || parsed < 200) {
                      return 'El monto mínimo es \$200';
                    }
                    return null;
                  },
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
                    const Expanded(
                      child: Text(
                        'Número de turnos / participantes:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                    const SizedBox(width: 8),
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

                // Fecha de inicio: de aquí salen las fechas de cada turno
                const Text(
                  '¿Cuándo empieza?',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 10),
                Material(
                  color: AppColors.darkSurface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.darkBorder),
                  ),
                  child: ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    leading: const Icon(Icons.event_outlined, color: AppColors.primary),
                    title: Text(
                      DateFormat("EEEE d 'de' MMMM 'de' y", 'es_MX').format(_startDate),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      _selectedFrequency == 'quincenal'
                          ? 'El primer cobro es el primer día 15 o fin de mes desde esta fecha'
                          : 'El primer turno cobra este día',
                      style: const TextStyle(fontSize: 12, color: AppColors.darkTextSecondary),
                    ),
                    trailing: const Icon(Icons.edit_calendar_outlined, size: 20),
                    onTap: _pickStartDate,
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
                  subtitle: 'Cada quien escoge su número libre antes de entrar a la tanda.',
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
                      : Text(
                          _isEditing ? 'Guardar cambios' : 'Crear Tanda Familiar 🎉',
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
    ),
  );
  }

  Widget _buildAssignmentOption({
    required String id,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _selectedAssignment == id;

    return LiquidGlassContainer(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedAssignment = id);
      },
      padding: const EdgeInsets.all(14),
      borderRadius: BrandConfig.inputRadius,
      opacity: isSelected ? 0.12 : 0.05,
      borderOpacity: isSelected ? 0.4 : 0.15,
      tintColor: isSelected ? AppColors.primary : Colors.white,
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
    );
  }
}
