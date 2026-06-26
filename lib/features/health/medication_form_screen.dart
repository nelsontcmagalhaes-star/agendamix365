import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../core/models.dart';
import '../../core/supabase_service.dart';
import '../../shared/widgets/app_card.dart';

class MedicationFormScreen extends StatefulWidget {
  final String? medicationId;
  const MedicationFormScreen({super.key, this.medicationId});

  @override
  State<MedicationFormScreen> createState() => _MedicationFormScreenState();
}

class _MedicationFormScreenState extends State<MedicationFormScreen> {
  final _nameCtrl = TextEditingController();
  final _dosageCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _scheduleCtrl = TextEditingController();
  List<String> _schedules = [];
  int _stock = 0;
  int? _stockAlert;
  bool _isActive = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.medicationId != null) _load();
  }

  Future<void> _load() async {
    final res = await supabase.from('medications').select().eq('id', widget.medicationId!).single();
    final m = MedicationModel.fromJson(res);
    setState(() {
      _nameCtrl.text = m.name;
      _dosageCtrl.text = m.dosage ?? '';
      _notesCtrl.text = m.notes ?? '';
      _schedules = List.from(m.schedules);
      _stock = m.stockQuantity;
      _stockAlert = m.stockAlertAt;
      _isActive = m.isActive;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dosageCtrl.dispose();
    _notesCtrl.dispose();
    _scheduleCtrl.dispose();
    super.dispose();
  }

  void _addSchedule() {
    if (_scheduleCtrl.text.trim().isNotEmpty) {
      setState(() {
        _schedules.add(_scheduleCtrl.text.trim());
        _scheduleCtrl.clear();
      });
    }
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    if (!SupabaseService.requirePremium(context)) return;
    setState(() => _loading = true);
    final data = {
      'user_id': SupabaseService.currentUserId!,
      'name': _nameCtrl.text.trim(),
      'dosage': _dosageCtrl.text.trim().isEmpty ? null : _dosageCtrl.text.trim(),
      'schedules': _schedules,
      'stock_quantity': _stock,
      'stock_alert_at': _stockAlert,
      'is_active': _isActive,
      'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    };
    try {
      if (widget.medicationId != null) {
        await supabase.from('medications').update(data).eq('id', widget.medicationId!);
      } else {
        await supabase.from('medications').insert(data);
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
        title: Text(widget.medicationId != null ? 'Editar medicamento' : 'Novo medicamento'),
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
            child: Column(
              children: [
                TextField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Nome do medicamento',
                    border: InputBorder.none,
                    filled: false,
                    prefixIcon: Icon(Icons.medication_rounded, color: AppColors.greenMedium),
                  ),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Divider(),
                TextField(
                  controller: _dosageCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Dosagem (ex: 500mg)',
                    border: InputBorder.none,
                    filled: false,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Horários', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _scheduleCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Ex: 08:00',
                          prefixIcon: Icon(Icons.access_time_rounded, color: AppColors.greyMedium),
                        ),
                        onSubmitted: (_) => _addSchedule(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _addSchedule,
                      icon: const Icon(Icons.add_circle_rounded, color: AppColors.greenMedium, size: 32),
                    ),
                  ],
                ),
                if (_schedules.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _schedules.map((s) => Chip(
                      label: Text(s),
                      deleteIcon: const Icon(Icons.close_rounded, size: 16),
                      onDeleted: () => setState(() => _schedules.remove(s)),
                      backgroundColor: AppColors.greenLight.withOpacity(0.15),
                      labelStyle: const TextStyle(color: AppColors.greenDark, fontSize: 12),
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Estoque atual'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: AppColors.greyMedium),
                        onPressed: _stock > 0 ? () => setState(() => _stock--) : null,
                      ),
                      Text('$_stock', style: Theme.of(context).textTheme.titleMedium),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: AppColors.greenMedium),
                        onPressed: () => setState(() => _stock++),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 0),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Medicamento ativo'),
                  value: _isActive,
                  activeColor: AppColors.greenMedium,
                  onChanged: (v) => setState(() => _isActive = v),
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
}
