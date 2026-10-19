import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/tanda_journey_timeline.dart';

class TandaDetailScreen extends StatefulWidget {
  const TandaDetailScreen({super.key});

  @override
  State<TandaDetailScreen> createState() => _TandaDetailScreenState();
}

class _TandaDetailScreenState extends State<TandaDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<SlotItemData> sampleSlots = [
    SlotItemData(
      slotNumber: 1,
      userName: 'Carlos Pérez (Tú)',
      dueDate: DateTime.now().subtract(const Duration(days: 30)),
      amount: 10000,
      isCompleted: true,
    ),
    SlotItemData(
      slotNumber: 2,
      userName: 'Tía Rosa',
      dueDate: DateTime.now().subtract(const Duration(days: 15)),
      amount: 10000,
      isCompleted: true,
    ),
    SlotItemData(
      slotNumber: 3,
      userName: 'Mariana López',
      dueDate: DateTime.now().add(const Duration(days: 2)),
      amount: 10000,
      isCurrent: true,
    ),
    SlotItemData(
      slotNumber: 4,
      userName: 'Primo Juan',
      dueDate: DateTime.now().add(const Duration(days: 17)),
      amount: 10000,
    ),
    SlotItemData(
      slotNumber: 5,
      userName: 'Tío Roberto',
      dueDate: DateTime.now().add(const Duration(days: 32)),
      amount: 10000,
    ),
    SlotItemData(
      slotNumber: 6,
      userName: 'Hermana Sofía',
      dueDate: DateTime.now().add(const Duration(days: 47)),
      amount: 10000,
    ),
    SlotItemData(
      slotNumber: 7,
      userName: 'Mamá Elena',
      dueDate: DateTime.now().add(const Duration(days: 62)),
      amount: 10000,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: '\$');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tanda Familiar Fin de Año'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AppColors.primary),
            tooltip: 'Compartir código por WhatsApp',
            onPressed: () {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Enlace de WhatsApp copiado para invitar a la familia 🎉'),
                  backgroundColor: AppColors.primaryDark,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Tarjeta de Ronda Activa
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.darkSurface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.star, color: AppColors.gold, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Ronda Activa #3 de 10',
                            style: TextStyle(
                              color: AppColors.gold,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Corte: 31 Oct',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Beneficiaria de la bolsa:',
                    style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Mariana López',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        currencyFormat.format(10000),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.gold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Recaudado: \$7,000 MXN',
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                      Text(
                        '7 de 10 pagaron',
                        style: TextStyle(fontSize: 12, color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: const LinearProgressIndicator(
                      value: 0.7,
                      backgroundColor: Colors.black26,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Selector de Pestañas
          TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.darkTextSecondary,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            tabs: const [
              Tab(text: 'El Camino (Turnos)'),
              Tab(text: 'Aportaciones'),
            ],
          ),

          // Contenido de las Pestañas
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: El Camino de la Tanda
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
                  child: TandaJourneyTimeline(
                    slots: sampleSlots,
                    onSlotTap: (slot) {
                      _showSlotDetailModal(context, slot);
                    },
                  ),
                ),

                // Tab 2: Aportaciones de la Ronda
                ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
                  children: [
                    _buildPaymentStatusItem('Carlos Pérez', 1000, true, 'Hace 2 horas'),
                    _buildPaymentStatusItem('Tía Rosa', 1000, true, 'Ayer'),
                    _buildPaymentStatusItem('Hermana Sofía', 1000, true, 'Hace 1 día'),
                    _buildPaymentStatusItem('Primo Juan', 1000, false, 'Pendiente de pago'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.lightImpact();
          _showPaymentModal(context);
        },
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.darkBg,
        icon: const Icon(Icons.receipt_long),
        label: const Text(
          'Registrar Aportación',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildPaymentStatusItem(String name, double amount, bool paid, String time) {
    final currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: '\$');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: paid ? AppColors.primary.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
                child: Icon(
                  paid ? Icons.check : Icons.access_time,
                  color: paid ? AppColors.primary : Colors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(time, style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 12)),
                ],
              ),
            ],
          ),
          Text(
            currencyFormat.format(amount),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: paid ? Colors.white : Colors.white60,
            ),
          ),
        ],
      ),
    );
  }

  void _showSlotDetailModal(BuildContext context, SlotItemData slot) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Turno #${slot.slotNumber} • ${slot.userName}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Fecha de cobro: ${DateFormat('dd MMMM yyyy', 'es_MX').format(slot.dueDate)}',
                style: const TextStyle(color: AppColors.darkTextSecondary),
              ),
              const SizedBox(height: 20),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.account_balance, color: AppColors.primary),
                title: const Text('Bolsa total a recibir'),
                trailing: Text(
                  '\$10,000 MXN',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.gold),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPaymentModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Registrar Aportación Quincenal',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Cuota: \$1,000 MXN • Ronda #3',
                style: TextStyle(color: AppColors.darkTextSecondary),
              ),
              const SizedBox(height: 24),
              // Botón para subir captura de transferencia
              InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Comprobante subido. En espera de aprobación del organizador ⏱️'),
                      backgroundColor: AppColors.primaryDark,
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), style: BorderStyle.solid),
                    color: AppColors.primary.withValues(alpha: 0.08),
                  ),
                  child: Column(
                    children: const [
                      Icon(Icons.camera_alt_outlined, size: 36, color: AppColors.primary),
                      SizedBox(height: 10),
                      Text(
                        'Adjuntar foto del comprobante o SPEI',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Sube la captura de tu banco',
                        style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
