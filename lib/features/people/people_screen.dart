import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../core/models.dart';
import '../../core/supabase_service.dart';
import '../../shared/widgets/app_card.dart';

class PeopleScreen extends StatefulWidget {
  const PeopleScreen({super.key});

  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<PersonModel> _people = [];
  List<SpecialDateModel> _specialDates = [];
  bool _loading = true;
  String _search = '';

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

    final [peopleRes, datesRes] = await Future.wait([
      supabase.from('people').select().eq('user_id', uid).order('name'),
      supabase.from('special_dates').select().eq('user_id', uid).order('month').order('day'),
    ]);

    if (mounted) {
      setState(() {
        _people = (peopleRes as List).map((e) => PersonModel.fromJson(e)).toList();
        _specialDates = (datesRes as List).map((e) => SpecialDateModel.fromJson(e)).toList();
        _loading = false;
      });
    }
  }

  List<PersonModel> get _filteredPeople => _people
      .where((p) => _search.isEmpty || p.name.toLowerCase().contains(_search.toLowerCase()))
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pessoas & Datas'),
        bottom: TabBar(
          controller: _tab,
          labelColor: AppColors.greenMedium,
          unselectedLabelColor: AppColors.greyMedium,
          indicatorColor: AppColors.greenMedium,
          tabs: const [Tab(text: 'Pessoas'), Tab(text: 'Datas Especiais')],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () {
              if (_tab.index == 0) {
                context.push('/people/new').then((_) => _load());
              } else {
                _showAddSpecialDate();
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
                _PeopleTab(people: _filteredPeople, search: _search, onSearch: (v) => setState(() => _search = v), onRefresh: _load),
                _SpecialDatesTab(dates: _specialDates, onRefresh: _load),
              ],
            ),
    );
  }

  void _showAddSpecialDate() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AddSpecialDateSheet(onSaved: _load),
    );
  }
}

class _PeopleTab extends StatelessWidget {
  final List<PersonModel> people;
  final String search;
  final ValueChanged<String> onSearch;
  final VoidCallback onRefresh;

  const _PeopleTab({required this.people, required this.search, required this.onSearch, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            onChanged: onSearch,
            decoration: const InputDecoration(
              hintText: 'Buscar pessoa...',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
        ),
        Expanded(
          child: people.isEmpty
              ? EmptyState(
                  icon: Icons.people_outline_rounded,
                  title: 'Nenhuma pessoa cadastrada',
                  actionLabel: 'Adicionar pessoa',
                  onAction: () => context.push('/people/new').then((_) => onRefresh()),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  itemCount: people.length,
                  itemBuilder: (context, i) {
                    final p = people[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: AppCard(
                        onTap: () => context.push('/people/edit/${p.id}').then((_) => onRefresh()),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: AppColors.greenLight.withOpacity(0.2),
                              backgroundImage: p.photoUrl != null ? NetworkImage(p.photoUrl!) : null,
                              child: p.photoUrl == null
                                  ? Text(p.name[0].toUpperCase(),
                                      style: const TextStyle(color: AppColors.greenDark, fontWeight: FontWeight.w700))
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.name, style: Theme.of(context).textTheme.titleMedium),
                                  if (p.relationship != null)
                                    Text(p.relationship!, style: Theme.of(context).textTheme.bodyMedium),
                                ],
                              ),
                            ),
                            if (p.phone != null)
                              const Icon(Icons.phone_outlined, color: AppColors.greenMedium, size: 18),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _SpecialDatesTab extends StatelessWidget {
  final List<SpecialDateModel> dates;
  final VoidCallback onRefresh;

  const _SpecialDatesTab({required this.dates, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (dates.isEmpty) {
      return EmptyState(
        icon: Icons.cake_outlined,
        title: 'Nenhuma data especial',
        subtitle: 'Cadastre aniversários, casamentos e muito mais!',
      );
    }

    final sorted = [...dates]..sort((a, b) => a.daysUntilNext().compareTo(b.daysUntilNext()));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: sorted.length,
      itemBuilder: (context, i) {
        final d = sorted[i];
        final days = d.daysUntilNext();
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: AppCard(
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: days <= 7 ? AppColors.greenLight.withOpacity(0.2) : AppColors.greySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: days <= 7 ? AppColors.greenDark : AppColors.greyMedium,
                          )),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.title, style: Theme.of(context).textTheme.titleMedium),
                      Text(d.type, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: days == 0
                        ? AppColors.greenMedium
                        : days <= 7
                            ? AppColors.greenLight.withOpacity(0.2)
                            : AppColors.greySoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    days == 0 ? 'Hoje!' : days == 1 ? 'Amanhã' : '$days dias',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: days == 0 ? AppColors.white : days <= 7 ? AppColors.greenDark : AppColors.greyMedium,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AddSpecialDateSheet extends StatefulWidget {
  final VoidCallback onSaved;
  const _AddSpecialDateSheet({required this.onSaved});

  @override
  State<_AddSpecialDateSheet> createState() => _AddSpecialDateSheetState();
}

class _AddSpecialDateSheetState extends State<_AddSpecialDateSheet> {
  final _titleCtrl = TextEditingController();
  String _type = 'Aniversário';
  int _day = DateTime.now().day;
  int _month = DateTime.now().month;
  bool _loading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    if (!SupabaseService.requirePremium(context)) return;
    setState(() => _loading = true);
    await supabase.from('special_dates').insert({
      'user_id': SupabaseService.currentUserId!,
      'title': _titleCtrl.text.trim(),
      'type': _type,
      'day': _day,
      'month': _month,
      'alert_enabled': true,
    });
    widget.onSaved();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nova data especial', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          TextField(
            controller: _titleCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(hintText: 'Ex: Aniversário de João'),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _type,
            decoration: const InputDecoration(labelText: 'Tipo'),
            items: AppCategories.specialDateType
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (v) => setState(() => _type = v!),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _day,
                  decoration: const InputDecoration(labelText: 'Dia'),
                  items: List.generate(31, (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}'))),
                  onChanged: (v) => setState(() => _day = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _month,
                  decoration: const InputDecoration(labelText: 'Mês'),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('Jan')),
                    DropdownMenuItem(value: 2, child: Text('Fev')),
                    DropdownMenuItem(value: 3, child: Text('Mar')),
                    DropdownMenuItem(value: 4, child: Text('Abr')),
                    DropdownMenuItem(value: 5, child: Text('Mai')),
                    DropdownMenuItem(value: 6, child: Text('Jun')),
                    DropdownMenuItem(value: 7, child: Text('Jul')),
                    DropdownMenuItem(value: 8, child: Text('Ago')),
                    DropdownMenuItem(value: 9, child: Text('Set')),
                    DropdownMenuItem(value: 10, child: Text('Out')),
                    DropdownMenuItem(value: 11, child: Text('Nov')),
                    DropdownMenuItem(value: 12, child: Text('Dez')),
                  ],
                  onChanged: (v) => setState(() => _month = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: GradientButton(label: 'Salvar', onTap: _loading ? () {} : _save, isLoading: _loading),
          ),
        ],
      ),
    );
  }
}
