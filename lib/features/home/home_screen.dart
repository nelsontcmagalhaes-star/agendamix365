import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../core/supabase_service.dart';
import '../../core/models.dart';
import '../../shared/widgets/app_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = '';
  List<AppointmentModel> _todayAppointments = [];
  List<ReminderModel> _todayReminders = [];
  List<SpecialDateModel> _upcomingDates = [];
  List<MedicationModel> _medications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final uid = SupabaseService.currentUserId;
    if (uid == null) return;

    try {
      final user = SupabaseService.currentUser;
      final meta = user?.userMetadata;
      _userName = meta?['full_name']?.toString().split(' ').first ?? 'você';

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      final apptRes = await supabase
          .from('appointments')
          .select()
          .eq('user_id', uid)
          .gte('start_time', todayStart.toIso8601String())
          .lt('start_time', todayEnd.toIso8601String())
          .order('start_time');

      final remRes = await supabase
          .from('reminders')
          .select()
          .eq('user_id', uid)
          .eq('is_done', false)
          .gte('due_date', todayStart.toIso8601String())
          .lt('due_date', todayEnd.toIso8601String())
          .order('due_date');

      final medRes = await supabase
          .from('medications')
          .select()
          .eq('user_id', uid)
          .eq('is_active', true)
          .limit(5);

      final specialRes = await supabase
          .from('special_dates')
          .select()
          .eq('user_id', uid)
          .eq('alert_enabled', true);

      if (mounted) {
        setState(() {
          _todayAppointments = (apptRes as List).map((e) => AppointmentModel.fromJson(e)).toList();
          _todayReminders = (remRes as List).map((e) => ReminderModel.fromJson(e)).toList();
          _medications = (medRes as List).map((e) => MedicationModel.fromJson(e)).toList();
          final allDates = (specialRes as List).map((e) => SpecialDateModel.fromJson(e)).toList();
          _upcomingDates = allDates
              .where((d) => d.daysUntilNext() <= 7)
              .toList()
            ..sort((a, b) => a.daysUntilNext().compareTo(b.daysUntilNext()));
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.greenMedium,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (_loading)
                    const Center(child: CircularProgressIndicator())
                  else ...[
                    if (_upcomingDates.isNotEmpty) ...[
                      _buildUpcomingDatesAlert(),
                      const SizedBox(height: 16),
                    ],
                    _buildQuickActions(),
                    const SizedBox(height: 20),
                    _buildTodaySection(),
                    const SizedBox(height: 20),
                    if (_medications.isNotEmpty) ...[
                      _buildMedicationsSection(),
                      const SizedBox(height: 20),
                    ],
                    _buildFinancialSummary(),
                    const SizedBox(height: 80),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 160,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.greenLight, AppColors.greenDark],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '${AppFormatters.greetingByHour()}, $_userName 👋',
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _capitalize(AppFormatters.formatWeekday(DateTime.now())),
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                AppFormatters.formatDate(DateTime.now()),
                style: TextStyle(
                  color: AppColors.white.withOpacity(0.85),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search_rounded, color: AppColors.white),
          onPressed: () => _showSearch(),
        ),
        IconButton(
          icon: const Icon(Icons.person_outline_rounded, color: AppColors.white),
          onPressed: () => _showProfile(),
        ),
      ],
    );
  }

  Widget _buildUpcomingDatesAlert() {
    final date = _upcomingDates.first;
    final days = date.daysUntilNext();
    return AppCard(
      color: AppColors.greenLight.withOpacity(0.12),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.greenMedium,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.cake_rounded, color: AppColors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  days == 0
                      ? 'Hoje é ${date.title}'
                      : 'Daqui a $days ${days == 1 ? 'dia' : 'dias'}: ${date.title}',
                  style: Theme.of(context).textTheme.titleMedium!
                      .copyWith(color: AppColors.greenDark),
                ),
                if (days > 0)
                  Text(
                    'Deseja comprar presente ou enviar mensagem?',
                    style: Theme.of(context).textTheme.bodyMedium!
                        .copyWith(fontSize: 12),
                  ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: AppColors.greenMedium),
        ],
      ),
      onTap: () => context.go('/people'),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Acesso rápido', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _QuickActionItem(icon: Icons.note_add_rounded, label: 'Nota', color: AppColors.info, onTap: () => context.push('/notes/new')),
              _QuickActionItem(icon: Icons.alarm_add_rounded, label: 'Lembrete', color: AppColors.warning, onTap: () => context.push('/reminders/new')),
              _QuickActionItem(icon: Icons.event_rounded, label: 'Compromisso', color: AppColors.greenMedium, onTap: () => context.push('/agenda/new')),
              _QuickActionItem(icon: Icons.people_outline_rounded, label: 'Pessoas', color: const Color(0xFF8B5CF6), onTap: () => context.go('/people')),
              _QuickActionItem(icon: Icons.folder_outlined, label: 'Documentos', color: const Color(0xFFEC4899), onTap: () => context.go('/documents')),
              _QuickActionItem(icon: Icons.sticky_note_2_outlined, label: 'Anotações', color: AppColors.greenDark, onTap: () => context.go('/notes')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTodaySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Meu dia',
          actionLabel: 'Ver agenda',
          onAction: () => context.go('/agenda'),
        ),
        const SizedBox(height: 12),
        if (_todayAppointments.isEmpty && _todayReminders.isEmpty)
          AppCard(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(Icons.wb_sunny_rounded, color: AppColors.greenLight, size: 40),
                    const SizedBox(height: 12),
                    Text('Dia livre!', style: Theme.of(context).textTheme.headlineSmall),
                    Text('Nenhum compromisso para hoje.', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
          )
        else ...[
          ..._todayAppointments.map((a) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _AppointmentTile(appointment: a),
          )),
          ..._todayReminders.map((r) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ReminderTile(reminder: r, onToggle: _loadData),
          )),
        ],
      ],
    );
  }

  Widget _buildMedicationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Medicamentos',
          actionLabel: 'Ver todos',
          onAction: () => context.go('/health'),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            children: _medications.map((m) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.greenLight.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.medication_rounded, color: AppColors.greenMedium, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.name, style: Theme.of(context).textTheme.titleMedium),
                        if (m.dosage != null)
                          Text(m.dosage!, style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  if (m.schedules.isNotEmpty)
                    Text(
                      m.schedules.first,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.greenMedium,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialSummary() {
    return AppCard(
      onTap: () => context.go('/financial'),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.greenLight.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.greenMedium),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Financeiro', style: Theme.of(context).textTheme.titleMedium),
                Text('Toque para ver resumo', style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.greyMedium),
        ],
      ),
    );
  }

  String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  void _showSearch() {
    showSearch(context: context, delegate: _UniversalSearch());
  }

  void _showProfile() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ProfileSheet(),
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _AppointmentTile extends StatelessWidget {
  final AppointmentModel appointment;
  const _AppointmentTile({required this.appointment});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 4,
            height: 48,
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
                Text(
                  AppFormatters.formatTime(appointment.startTime),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.greenLight.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              appointment.category,
              style: const TextStyle(fontSize: 11, color: AppColors.greenDark, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderTile extends StatefulWidget {
  final ReminderModel reminder;
  final VoidCallback onToggle;
  const _ReminderTile({required this.reminder, required this.onToggle});

  @override
  State<_ReminderTile> createState() => _ReminderTileState();
}

class _ReminderTileState extends State<_ReminderTile> {
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _done = widget.reminder.isDone;
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          GestureDetector(
            onTap: _toggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _done ? AppColors.greenMedium : Colors.transparent,
                border: Border.all(
                  color: _done ? AppColors.greenMedium : AppColors.greyMedium,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: _done ? const Icon(Icons.check_rounded, color: AppColors.white, size: 14) : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.reminder.title,
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                decoration: _done ? TextDecoration.lineThrough : null,
                color: _done ? AppColors.greyMedium : AppColors.textPrimary,
              ),
            ),
          ),
          Icon(Icons.alarm_outlined, size: 16, color: AppColors.warning),
          const SizedBox(width: 4),
          Text(
            AppFormatters.formatTime(widget.reminder.dueDate),
            style: const TextStyle(fontSize: 12, color: AppColors.greyMedium),
          ),
        ],
      ),
    );
  }

  Future<void> _toggle() async {
    setState(() => _done = !_done);
    await supabase
        .from('reminders')
        .update({'is_done': _done})
        .eq('id', widget.reminder.id);
    widget.onToggle();
  }
}

class _UniversalSearch extends SearchDelegate<String> {
  @override
  String get searchFieldLabel => 'Buscar compromissos, notas, pessoas...';

  @override
  List<Widget> buildActions(BuildContext context) => [
    IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
  ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back_rounded),
    onPressed: () => close(context, ''),
  );

  @override
  Widget buildResults(BuildContext context) => _buildSuggestions(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildSuggestions(context);

  Widget _buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return const Center(
        child: Text('Digite para buscar', style: TextStyle(color: AppColors.greyMedium)),
      );
    }
    return FutureBuilder(
      future: _search(query),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final results = snapshot.data as List<Map<String, dynamic>>;
        if (results.isEmpty) {
          return const Center(child: Text('Nenhum resultado encontrado'));
        }
        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, i) {
            final item = results[i];
            return ListTile(
              leading: Icon(item['icon'] as IconData, color: AppColors.greenMedium),
              title: Text(item['title'] as String),
              subtitle: Text(item['subtitle'] as String),
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _search(String q) async {
    final uid = SupabaseService.currentUserId;
    if (uid == null) return [];
    final lower = q.toLowerCase();
    final results = <Map<String, dynamic>>[];

    final appts = await supabase
        .from('appointments')
        .select('title, start_time')
        .eq('user_id', uid)
        .ilike('title', '%$lower%')
        .limit(5);
    for (final a in appts) {
      results.add({'icon': Icons.event_rounded, 'title': a['title'], 'subtitle': 'Compromisso'});
    }

    final notes = await supabase
        .from('notes')
        .select('title, category')
        .eq('user_id', uid)
        .ilike('title', '%$lower%')
        .limit(5);
    for (final n in notes) {
      results.add({'icon': Icons.note_rounded, 'title': n['title'], 'subtitle': 'Nota'});
    }

    final people = await supabase
        .from('people')
        .select('name, relationship')
        .eq('user_id', uid)
        .ilike('name', '%$lower%')
        .limit(5);
    for (final p in people) {
      results.add({'icon': Icons.person_rounded, 'title': p['name'], 'subtitle': 'Pessoa'});
    }

    return results;
  }
}

class _ProfileSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = SupabaseService.currentUser;
    final name = user?.userMetadata?['full_name'] ?? 'Usuário';
    final email = user?.email ?? '';

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(color: AppColors.greySoft, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.greenLight.withOpacity(0.15),
            child: Text(
              name.toString().isNotEmpty ? name.toString()[0].toUpperCase() : 'U',
              style: const TextStyle(fontSize: 32, color: AppColors.greenDark, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 16),
          Text(name.toString(), style: Theme.of(context).textTheme.headlineMedium),
          Text(email, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 24),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppColors.error),
            title: const Text('Sair', style: TextStyle(color: AppColors.error)),
            onTap: () async {
              await SupabaseService.signOut();
              if (context.mounted) context.go('/auth/login');
            },
          ),
        ],
      ),
    );
  }
}
