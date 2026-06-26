import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../core/models.dart';
import '../../core/supabase_service.dart';
import '../../shared/widgets/app_card.dart';

class AppointmentFormScreen extends StatefulWidget {
  final String? appointmentId;
  const AppointmentFormScreen({super.key, this.appointmentId});

  @override
  State<AppointmentFormScreen> createState() => _AppointmentFormScreenState();
}

class _AppointmentFormScreenState extends State<AppointmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay? _endTime;
  String _category = 'Pessoal';
  String _repeat = 'Nunca';
  bool _notify = false;
  int _notifyBefore = 30;
  bool _loading = false;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    if (widget.appointmentId != null) {
      _editing = true;
      _loadAppointment();
    }
  }

  Future<void> _loadAppointment() async {
    final res = await supabase
        .from('appointments')
        .select()
        .eq('id', widget.appointmentId!)
        .single();
    final appt = AppointmentModel.fromJson(res);
    setState(() {
      _titleCtrl.text = appt.title;
      _locationCtrl.text = appt.location ?? '';
      _notesCtrl.text = appt.notes ?? '';
      _startDate = appt.startTime;
      _startTime = TimeOfDay.fromDateTime(appt.startTime);
      if (appt.endTime != null) _endTime = TimeOfDay.fromDateTime(appt.endTime!);
      _category = appt.category;
      _repeat = appt.repeat ?? 'Nunca';
      _notify = appt.notifyEnabled;
      _notifyBefore = appt.notifyMinutesBefore ?? 30;
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _locationCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!SupabaseService.requirePremium(context)) return;
    setState(() => _loading = true);

    final uid = SupabaseService.currentUserId!;
    final startDt = DateTime(
      _startDate.year, _startDate.month, _startDate.day,
      _startTime.hour, _startTime.minute,
    );
    DateTime? endDt;
    if (_endTime != null) {
      endDt = DateTime(
        _startDate.year, _startDate.month, _startDate.day,
        _endTime!.hour, _endTime!.minute,
      );
    }

    final data = {
      'user_id': uid,
      'title': _titleCtrl.text.trim(),
      'start_time': startDt.toIso8601String(),
      'end_time': endDt?.toIso8601String(),
      'location': _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
      'category': _category,
      'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      'repeat': _repeat == 'Nunca' ? null : _repeat,
      'notify_enabled': _notify,
      'notify_minutes_before': _notify ? _notifyBefore : null,
    };

    try {
      if (_editing) {
        await supabase.from('appointments').update(data).eq('id', widget.appointmentId!);
      } else {
        await supabase.from('appointments').insert(data);
      }
      if (mounted) context.pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao salvar compromisso')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_editing ? 'Editar compromisso' : 'Novo compromisso'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _loading ? null : _save,
            child: _loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Salvar'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppCard(
              child: Column(
                children: [
                  TextFormField(
                    controller: _titleCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Título do compromisso',
                      border: InputBorder.none,
                      filled: false,
                    ),
                    style: Theme.of(context).textTheme.headlineSmall,
                    validator: (v) => (v == null || v.isEmpty) ? 'Informe o título' : null,
                  ),
                  const Divider(),
                  TextFormField(
                    controller: _locationCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Local (opcional)',
                      border: InputBorder.none,
                      filled: false,
                      prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.greyMedium),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                children: [
                  _DateRow(
                    label: 'Data',
                    value: AppFormatters.formatDate(_startDate),
                    onTap: _pickDate,
                  ),
                  const Divider(height: 0),
                  _TimeRow(
                    label: 'Início',
                    value: _startTime.format(context),
                    onTap: _pickStartTime,
                  ),
                  const Divider(height: 0),
                  _TimeRow(
                    label: 'Término',
                    value: _endTime?.format(context) ?? 'Adicionar',
                    onTap: _pickEndTime,
                    isPlaceholder: _endTime == null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text('Categoria', style: Theme.of(context).textTheme.titleMedium),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AppCategories.appointment.map((c) => CategoryChip(
                      label: c,
                      color: AppColors.greenMedium,
                      isSelected: _category == c,
                      onTap: () => setState(() => _category = c),
                    )).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                children: [
                  _RepeatRow(
                    value: _repeat,
                    onChange: (v) => setState(() => _repeat = v),
                  ),
                  const Divider(height: 0),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Notificação'),
                    subtitle: _notify
                        ? Text('$_notifyBefore minutos antes')
                        : null,
                    value: _notify,
                    activeColor: AppColors.greenMedium,
                    onChanged: (v) => setState(() => _notify = v),
                  ),
                  if (_notify) ...[
                    const Divider(height: 0),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          const Text('Avisar com antecedência'),
                          const Spacer(),
                          DropdownButton<int>(
                            value: _notifyBefore,
                            underline: const SizedBox(),
                            items: [5, 10, 15, 30, 60, 120].map((m) => DropdownMenuItem(
                              value: m,
                              child: Text('$m min'),
                            )).toList(),
                            onChanged: (v) => setState(() => _notifyBefore = v!),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: TextFormField(
                controller: _notesCtrl,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Observações (opcional)',
                  border: InputBorder.none,
                  filled: false,
                ),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(context: context, initialTime: _startTime);
    if (picked != null) setState(() => _startTime = picked);
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(context: context, initialTime: _endTime ?? _startTime);
    if (picked != null) setState(() => _endTime = picked);
  }
}

class _DateRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DateRow({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.calendar_today_outlined, color: AppColors.greenMedium),
      title: Text(label),
      trailing: GestureDetector(
        onTap: onTap,
        child: Text(
          value,
          style: const TextStyle(color: AppColors.greenMedium, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool isPlaceholder;

  const _TimeRow({
    required this.label,
    required this.value,
    required this.onTap,
    this.isPlaceholder = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.access_time_rounded, color: AppColors.greenMedium),
      title: Text(label),
      trailing: GestureDetector(
        onTap: onTap,
        child: Text(
          value,
          style: TextStyle(
            color: isPlaceholder ? AppColors.greyMedium : AppColors.greenMedium,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _RepeatRow extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChange;

  const _RepeatRow({required this.value, required this.onChange});

  @override
  Widget build(BuildContext context) {
    const options = ['Nunca', 'Diário', 'Semanal', 'Mensal', 'Anual'];
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.repeat_rounded, color: AppColors.greenMedium),
      title: const Text('Repetição'),
      trailing: DropdownButton<String>(
        value: value,
        underline: const SizedBox(),
        items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
        onChanged: (v) => onChange(v!),
      ),
    );
  }
}
