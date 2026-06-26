import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../core/models.dart';
import '../../core/supabase_service.dart';
import '../../shared/widgets/app_card.dart';

class ReminderFormScreen extends StatefulWidget {
  final String? reminderId;
  const ReminderFormScreen({super.key, this.reminderId});

  @override
  State<ReminderFormScreen> createState() => _ReminderFormScreenState();
}

class _ReminderFormScreenState extends State<ReminderFormScreen> {
  final _titleCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime _dueDate = DateTime.now().add(const Duration(hours: 1));
  bool _alarm = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.reminderId != null) _load();
  }

  Future<void> _load() async {
    final res = await supabase.from('reminders').select().eq('id', widget.reminderId!).single();
    final r = ReminderModel.fromJson(res);
    setState(() {
      _titleCtrl.text = r.title;
      _notesCtrl.text = r.notes ?? '';
      _dueDate = r.dueDate;
      _alarm = r.alarmEnabled;
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    if (!SupabaseService.requirePremium(context)) return;
    setState(() => _loading = true);
    final data = {
      'user_id': SupabaseService.currentUserId!,
      'title': _titleCtrl.text.trim(),
      'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      'due_date': _dueDate.toIso8601String(),
      'alarm_enabled': _alarm,
      'is_done': false,
    };
    try {
      if (widget.reminderId != null) {
        await supabase.from('reminders').update(data).eq('id', widget.reminderId!);
      } else {
        await supabase.from('reminders').insert(data);
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
        title: Text(widget.reminderId != null ? 'Editar lembrete' : 'Novo lembrete'),
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
                hintText: 'O que você precisa lembrar?',
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
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today_outlined, color: AppColors.greenMedium),
                  title: const Text('Data'),
                  trailing: GestureDetector(
                    onTap: _pickDate,
                    child: Text(
                      AppFormatters.formatDate(_dueDate),
                      style: const TextStyle(color: AppColors.greenMedium, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const Divider(height: 0),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.access_time_rounded, color: AppColors.greenMedium),
                  title: const Text('Hora'),
                  trailing: GestureDetector(
                    onTap: _pickTime,
                    child: Text(
                      AppFormatters.formatTime(_dueDate),
                      style: const TextStyle(color: AppColors.greenMedium, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const Divider(height: 0),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ativar alarme'),
                  value: _alarm,
                  activeColor: AppColors.greenMedium,
                  onChanged: (v) => setState(() => _alarm = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: TextField(
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
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null) {
      setState(() => _dueDate = DateTime(
        picked.year, picked.month, picked.day,
        _dueDate.hour, _dueDate.minute,
      ));
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dueDate),
    );
    if (picked != null) {
      setState(() => _dueDate = DateTime(
        _dueDate.year, _dueDate.month, _dueDate.day,
        picked.hour, picked.minute,
      ));
    }
  }
}
