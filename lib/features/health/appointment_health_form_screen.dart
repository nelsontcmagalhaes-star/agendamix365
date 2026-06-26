import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../core/models.dart';
import '../../core/supabase_service.dart';
import '../../shared/widgets/app_card.dart';

class AppointmentHealthFormScreen extends StatefulWidget {
  final String? appointmentId;
  const AppointmentHealthFormScreen({super.key, this.appointmentId});

  @override
  State<AppointmentHealthFormScreen> createState() => _AppointmentHealthFormScreenState();
}

class _AppointmentHealthFormScreenState extends State<AppointmentHealthFormScreen> {
  final _titleCtrl = TextEditingController();
  final _doctorCtrl = TextEditingController();
  final _clinicCtrl = TextEditingController();
  final _specialtyCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _valueCtrl = TextEditingController();
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  DateTime? _returnDate;
  String _coverageType = 'Particular';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.appointmentId != null) _load();
  }

  Future<void> _load() async {
    final res = await supabase.from('health_appointments').select().eq('id', widget.appointmentId!).single();
    final a = HealthAppointmentModel.fromJson(res);
    setState(() {
      _titleCtrl.text = a.title;
      _doctorCtrl.text = a.doctorName ?? '';
      _clinicCtrl.text = a.clinic ?? '';
      _specialtyCtrl.text = a.specialty ?? '';
      _notesCtrl.text = a.notes ?? '';
      _valueCtrl.text = a.value != null ? a.value!.toStringAsFixed(2).replaceAll('.', ',') : '';
      _date = a.appointmentDate;
      _returnDate = a.returnDate;
      _coverageType = a.coverageType;
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _doctorCtrl.dispose();
    _clinicCtrl.dispose();
    _specialtyCtrl.dispose();
    _notesCtrl.dispose();
    _valueCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    if (!SupabaseService.requirePremium(context)) return;
    setState(() => _loading = true);
    final valueStr = _valueCtrl.text.trim().replaceAll(',', '.');
    final value = double.tryParse(valueStr);
    final data = {
      'user_id': SupabaseService.currentUserId!,
      'title': _titleCtrl.text.trim(),
      'doctor_name': _doctorCtrl.text.trim().isEmpty ? null : _doctorCtrl.text.trim(),
      'clinic': _clinicCtrl.text.trim().isEmpty ? null : _clinicCtrl.text.trim(),
      'specialty': _specialtyCtrl.text.trim().isEmpty ? null : _specialtyCtrl.text.trim(),
      'appointment_date': _date.toIso8601String(),
      'coverage_type': _coverageType,
      'value': value,
      'return_date': _returnDate?.toIso8601String(),
      'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    };
    try {
      if (widget.appointmentId != null) {
        await supabase.from('health_appointments').update(data).eq('id', widget.appointmentId!);
      } else {
        await supabase.from('health_appointments').insert(data);
      }
      if (mounted) context.pop();
    } catch (_) {} finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.appointmentId != null ? 'Editar consulta' : 'Nova consulta'),
        leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => context.pop()),
        actions: [
          TextButton(
            onPressed: _loading ? null : _save,
            child: _loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Salvar'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: TextField(
              controller: _titleCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Tipo de consulta ou exame',
                border: InputBorder.none,
                filled: false,
              ),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              children: [
                TextField(
                  controller: _doctorCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'Nome do médico',
                    border: InputBorder.none,
                    filled: false,
                    prefixIcon: Icon(Icons.person_outline, color: AppColors.greyMedium),
                  ),
                ),
                const Divider(height: 0),
                TextField(
                  controller: _specialtyCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'Especialidade (ex: Cardiologista)',
                    border: InputBorder.none,
                    filled: false,
                    prefixIcon: Icon(Icons.medical_services_outlined, color: AppColors.greyMedium),
                  ),
                ),
                const Divider(height: 0),
                TextField(
                  controller: _clinicCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'Clínica ou hospital',
                    border: InputBorder.none,
                    filled: false,
                    prefixIcon: Icon(Icons.local_hospital_outlined, color: AppColors.greyMedium),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today_outlined, color: AppColors.greenMedium),
                  title: const Text('Data e hora'),
                  trailing: GestureDetector(
                    onTap: _pickDate,
                    child: Text(
                      AppFormatters.formatDateTime(_date),
                      style: const TextStyle(color: AppColors.greenMedium, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const Divider(height: 0),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_repeat_rounded, color: AppColors.greenMedium),
                  title: const Text('Retorno'),
                  trailing: GestureDetector(
                    onTap: _pickReturnDate,
                    child: Text(
                      _returnDate != null ? AppFormatters.formatDate(_returnDate!) : 'Adicionar',
                      style: TextStyle(
                        color: _returnDate != null ? AppColors.greenMedium : AppColors.greyMedium,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const Divider(height: 0),
                DropdownButtonFormField<String>(
                  value: _coverageType,
                  decoration: const InputDecoration(
                    labelText: 'Cobertura',
                    border: InputBorder.none,
                    filled: false,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Particular', child: Text('Particular')),
                    DropdownMenuItem(value: 'Plano de saúde', child: Text('Plano de saúde')),
                  ],
                  onChanged: (v) => setState(() => _coverageType = v!),
                ),
                const Divider(height: 0),
                TextField(
                  controller: _valueCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    hintText: r'Valor (R$)',
                    border: InputBorder.none,
                    filled: false,
                    prefixIcon: Icon(Icons.attach_money_rounded, color: AppColors.greyMedium),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: TextField(
              controller: _notesCtrl,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Observações, resultados, próximos passos...',
                border: InputBorder.none,
                filled: false,
              ),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('pt', 'BR'),
    );
    if (date == null) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_date));
    if (time != null) {
      setState(() => _date = DateTime(date.year, date.month, date.day, time.hour, time.minute));
    }
  }

  Future<void> _pickReturnDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _returnDate ?? _date.add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      locale: const Locale('pt', 'BR'),
    );
    if (date != null) setState(() => _returnDate = date);
  }
}
