import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../core/models.dart';
import '../../core/supabase_service.dart';
import '../../shared/widgets/app_card.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<MedicationModel> _medications = [];
  List<HealthAppointmentModel> _appointments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final uid = SupabaseService.currentUserId;
    if (uid == null) return;

    final [medRes, apptRes] = await Future.wait([
      supabase.from('medications').select().eq('user_id', uid).order('name'),
      supabase.from('health_appointments').select().eq('user_id', uid).order('appointment_date', ascending: false),
    ]);

    if (mounted) {
      setState(() {
        _medications = (medRes as List).map((e) => MedicationModel.fromJson(e)).toList();
        _appointments = (apptRes as List).map((e) => HealthAppointmentModel.fromJson(e)).toList();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Saúde'),
        bottom: TabBar(
          controller: _tab,
          labelColor: AppColors.greenMedium,
          unselectedLabelColor: AppColors.greyMedium,
          indicatorColor: AppColors.greenMedium,
          tabs: const [Tab(text: 'Medicamentos'), Tab(text: 'Consultas')],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () {
              if (_tab.index == 0) {
                context.push('/health/medication/new').then((_) => _load());
              } else {
                context.push('/health/appointment/new').then((_) => _load());
              }
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tab,
              children: [
                _MedicationsTab(medications: _medications, onRefresh: _load),
                _AppointmentsTab(appointments: _appointments, onRefresh: _load),
              ],
            ),
    );
  }
}

class _MedicationsTab extends StatelessWidget {
  final List<MedicationModel> medications;
  final VoidCallback onRefresh;

  const _MedicationsTab({required this.medications, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (medications.isEmpty) {
      return EmptyState(
        icon: Icons.medication_outlined,
        title: 'Nenhum medicamento',
        actionLabel: 'Adicionar medicamento',
        onAction: () => context.push('/health/medication/new').then((_) => onRefresh()),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: medications.length,
      itemBuilder: (context, i) {
        final med = medications[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: AppCard(
            onTap: () => context.push('/health/medication/edit/${med.id}').then((_) => onRefresh()),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: med.isActive ? AppColors.greenLight.withOpacity(0.15) : AppColors.greySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.medication_rounded,
                      color: med.isActive ? AppColors.greenMedium : AppColors.greyMedium),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(med.name, style: Theme.of(context).textTheme.titleMedium),
                      if (med.dosage != null)
                        Text(med.dosage!, style: Theme.of(context).textTheme.bodyMedium),
                      if (med.schedules.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 4,
                          children: med.schedules.map((s) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.greenLight.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(s, style: const TextStyle(fontSize: 10, color: AppColors.greenDark)),
                          )).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (med.stockQuantity > 0)
                      Text(
                        '${med.stockQuantity} un.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: med.stockAlertAt != null && med.stockQuantity <= med.stockAlertAt!
                              ? AppColors.error
                              : AppColors.greyMedium,
                        ),
                      ),
                    if (!med.isActive)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.greySoft,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Inativo', style: TextStyle(fontSize: 10, color: AppColors.greyMedium)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AppointmentsTab extends StatelessWidget {
  final List<HealthAppointmentModel> appointments;
  final VoidCallback onRefresh;

  const _AppointmentsTab({required this.appointments, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (appointments.isEmpty) {
      return EmptyState(
        icon: Icons.medical_services_outlined,
        title: 'Nenhuma consulta',
        actionLabel: 'Adicionar consulta',
        onAction: () => context.push('/health/appointment/new').then((_) => onRefresh()),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: appointments.length,
      itemBuilder: (context, i) {
        final appt = appointments[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: AppCard(
            onTap: () => context.push('/health/appointment/edit/${appt.id}').then((_) => onRefresh()),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(appt.title, style: Theme.of(context).textTheme.titleMedium)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: appt.coverageType == 'Plano de saúde'
                            ? AppColors.greenLight.withOpacity(0.15)
                            : AppColors.greySoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        appt.coverageType,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: appt.coverageType == 'Plano de saúde' ? AppColors.greenDark : AppColors.greyMedium,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (appt.doctorName != null)
                  Text('Dr(a). ${appt.doctorName}', style: Theme.of(context).textTheme.bodyMedium),
                if (appt.clinic != null)
                  Text(appt.clinic!, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.greyMedium),
                    const SizedBox(width: 4),
                    Text(AppFormatters.formatDateTime(appt.appointmentDate),
                        style: const TextStyle(fontSize: 12, color: AppColors.greyMedium)),
                    if (appt.value != null) ...[
                      const Spacer(),
                      Text(AppFormatters.formatCurrency(appt.value!),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.greenDark)),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
