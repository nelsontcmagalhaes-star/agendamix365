import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../core/models.dart';
import '../../core/supabase_service.dart';
import '../../shared/widgets/app_card.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  List<ReminderModel> _reminders = [];
  bool _loading = true;
  bool _showDone = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = SupabaseService.currentUserId;
    if (uid == null) return;
    final query = supabase.from('reminders').select().eq('user_id', uid);
    final res = _showDone ? await query.order('due_date') : await query.eq('is_done', false).order('due_date');

    if (mounted) {
      setState(() {
        _reminders = (res as List).map((e) => ReminderModel.fromJson(e)).toList();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Lembretes'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _showDone = !_showDone);
              _load();
            },
            child: Text(_showDone ? 'Ocultar concluídos' : 'Ver concluídos'),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.push('/reminders/new').then((_) => _load()),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _reminders.isEmpty
              ? EmptyState(
                  icon: Icons.alarm_outlined,
                  title: 'Nenhum lembrete',
                  actionLabel: 'Criar lembrete',
                  onAction: () => context.push('/reminders/new').then((_) => _load()),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: _reminders.length,
                  itemBuilder: (context, i) {
                    final r = _reminders[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _ReminderCard(reminder: r, onRefresh: _load),
                    );
                  },
                ),
    );
  }
}

class _ReminderCard extends StatefulWidget {
  final ReminderModel reminder;
  final VoidCallback onRefresh;

  const _ReminderCard({required this.reminder, required this.onRefresh});

  @override
  State<_ReminderCard> createState() => _ReminderCardState();
}

class _ReminderCardState extends State<_ReminderCard> {
  late bool _done;

  @override
  void initState() {
    super.initState();
    _done = widget.reminder.isDone;
  }

  @override
  Widget build(BuildContext context) {
    final isOverdue = !_done && widget.reminder.dueDate.isBefore(DateTime.now());
    return AppCard(
      onTap: () => context.push('/reminders/edit/${widget.reminder.id}').then((_) => widget.onRefresh()),
      child: Row(
        children: [
          GestureDetector(
            onTap: _toggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: _done ? AppColors.greenMedium : Colors.transparent,
                border: Border.all(
                  color: _done ? AppColors.greenMedium : AppColors.greyMedium,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _done ? const Icon(Icons.check_rounded, color: AppColors.white, size: 16) : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.reminder.title,
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    decoration: _done ? TextDecoration.lineThrough : null,
                    color: _done ? AppColors.greyMedium : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.alarm_outlined,
                      size: 14,
                      color: isOverdue ? AppColors.error : AppColors.greyMedium,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      AppFormatters.relativeDateLabel(widget.reminder.dueDate),
                      style: TextStyle(
                        fontSize: 12,
                        color: isOverdue ? AppColors.error : AppColors.greyMedium,
                        fontWeight: isOverdue ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _delete,
            child: const Icon(Icons.delete_outline_rounded, color: AppColors.greyMedium, size: 20),
          ),
        ],
      ),
    );
  }

  Future<void> _toggle() async {
    setState(() => _done = !_done);
    await supabase.from('reminders').update({'is_done': _done}).eq('id', widget.reminder.id);
  }

  void _delete() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir lembrete'),
        content: Text('Deseja excluir "${widget.reminder.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              if (!SupabaseService.requirePremium(context)) return;
              await supabase.from('reminders').delete().eq('id', widget.reminder.id);
              if (context.mounted) Navigator.pop(context);
              widget.onRefresh();
            },
            child: const Text('Excluir', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
