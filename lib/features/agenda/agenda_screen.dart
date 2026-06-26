import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../core/models.dart';
import '../../core/supabase_service.dart';
import '../../shared/widgets/app_card.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _format = CalendarFormat.month;
  Map<DateTime, List<AppointmentModel>> _events = {};
  List<AppointmentModel> _selectedEvents = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final uid = SupabaseService.currentUserId;
    if (uid == null) return;

    final start = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
    final end = DateTime(_focusedDay.year, _focusedDay.month + 2, 1);

    final res = await supabase
        .from('appointments')
        .select()
        .eq('user_id', uid)
        .gte('start_time', start.toIso8601String())
        .lt('start_time', end.toIso8601String())
        .order('start_time');

    final events = <DateTime, List<AppointmentModel>>{};
    for (final item in res) {
      final appt = AppointmentModel.fromJson(item);
      final day = DateTime(appt.startTime.year, appt.startTime.month, appt.startTime.day);
      events.putIfAbsent(day, () => []).add(appt);
    }

    if (mounted) {
      setState(() {
        _events = events;
        _selectedEvents = _getEventsForDay(_selectedDay);
        _loading = false;
      });
    }
  }

  List<AppointmentModel> _getEventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _events[key] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Agenda'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.push('/agenda/new').then((_) => _loadEvents()),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.white,
            child: TableCalendar<AppointmentModel>(
              firstDay: DateTime(2020),
              lastDay: DateTime(2030),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              calendarFormat: _format,
              eventLoader: _getEventsForDay,
              startingDayOfWeek: StartingDayOfWeek.monday,
              locale: 'pt_BR',
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                todayDecoration: BoxDecoration(
                  color: AppColors.greenLight.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: const TextStyle(color: AppColors.greenDark, fontWeight: FontWeight.w700),
                selectedDecoration: const BoxDecoration(
                  color: AppColors.greenMedium,
                  shape: BoxShape.circle,
                ),
                markerDecoration: const BoxDecoration(
                  color: AppColors.greenDark,
                  shape: BoxShape.circle,
                ),
                weekendTextStyle: const TextStyle(color: AppColors.textPrimary),
              ),
              headerStyle: HeaderStyle(
                formatButtonDecoration: BoxDecoration(
                  color: AppColors.greenLight.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                formatButtonTextStyle: const TextStyle(color: AppColors.greenDark, fontSize: 12),
                titleCentered: true,
                titleTextStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                leftChevronIcon: const Icon(Icons.chevron_left_rounded, color: AppColors.textPrimary),
                rightChevronIcon: const Icon(Icons.chevron_right_rounded, color: AppColors.textPrimary),
              ),
              onDaySelected: (selected, focused) {
                setState(() {
                  _selectedDay = selected;
                  _focusedDay = focused;
                  _selectedEvents = _getEventsForDay(selected);
                });
              },
              onFormatChanged: (format) => setState(() => _format = format),
              onPageChanged: (focused) {
                _focusedDay = focused;
                _loadEvents();
              },
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _selectedEvents.isEmpty
                    ? EmptyState(
                        icon: Icons.event_available_rounded,
                        title: 'Nenhum compromisso',
                        subtitle: AppFormatters.formatDate(_selectedDay),
                        actionLabel: 'Adicionar',
                        onAction: () => context.push('/agenda/new').then((_) => _loadEvents()),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _selectedEvents.length,
                        itemBuilder: (context, i) {
                          final appt = _selectedEvents[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _AppointmentCard(
                              appointment: appt,
                              onDelete: _loadEvents,
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final VoidCallback onDelete;

  const _AppointmentCard({required this.appointment, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => context.push('/agenda/edit/${appointment.id}').then((_) => onDelete()),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.greenMedium,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(appointment.title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 14, color: AppColors.greyMedium),
                    const SizedBox(width: 4),
                    Text(
                      AppFormatters.formatTime(appointment.startTime),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (appointment.endTime != null) ...[
                      const Text(' — ', style: TextStyle(color: AppColors.greyMedium)),
                      Text(
                        AppFormatters.formatTime(appointment.endTime!),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
                if (appointment.location != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: AppColors.greyMedium),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          appointment.location!,
                          style: Theme.of(context).textTheme.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.greenLight.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  appointment.category,
                  style: const TextStyle(fontSize: 10, color: AppColors.greenDark, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _confirmDelete(context),
                child: const Icon(Icons.delete_outline_rounded, color: AppColors.greyMedium, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir compromisso'),
        content: Text('Deseja excluir "${appointment.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              if (!SupabaseService.requirePremium(context)) return;
              await supabase.from('appointments').delete().eq('id', appointment.id);
              if (context.mounted) Navigator.pop(context);
              onDelete();
            },
            child: const Text('Excluir', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
