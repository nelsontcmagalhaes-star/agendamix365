import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../core/supabase_service.dart';
import '../../shared/widgets/app_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchCtrl = TextEditingController();
  List<_SearchResult> _results = [];
  bool _loading = false;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onChanged);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onChanged() {
    final q = _searchCtrl.text.trim();
    if (q == _lastQuery) return;
    _lastQuery = q;
    if (q.length < 2) {
      setState(() => _results = []);
      return;
    }
    _search(q);
  }

  Future<void> _search(String q) async {
    setState(() => _loading = true);
    final uid = SupabaseService.currentUserId;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }
    final lower = q.toLowerCase();
    final results = <_SearchResult>[];

    try {
      // Compromissos
      final appts = await supabase
          .from('appointments')
          .select('id, title, start_time, category')
          .eq('user_id', uid)
          .ilike('title', '%$lower%')
          .limit(5);
      for (final a in appts) {
        results.add(_SearchResult(
          icon: Icons.event_rounded,
          color: AppColors.greenMedium,
          title: a['title'] as String,
          subtitle: 'Compromisso · ${AppFormatters.formatDateTime(DateTime.parse(a['start_time']))}',
          category: 'Compromissos',
          onTap: (ctx) => ctx.push('/agenda/edit/${a['id']}'),
        ));
      }

      // Notas
      final notes = await supabase
          .from('notes')
          .select('id, title, category')
          .eq('user_id', uid)
          .ilike('title', '%$lower%')
          .limit(5);
      for (final n in notes) {
        results.add(_SearchResult(
          icon: Icons.note_rounded,
          color: AppColors.info,
          title: n['title'] as String,
          subtitle: 'Anotação · ${n['category']}',
          category: 'Notas',
          onTap: (ctx) => ctx.push('/notes/edit/${n['id']}'),
        ));
      }

      // Lembretes
      final reminders = await supabase
          .from('reminders')
          .select('id, title, due_date, is_done')
          .eq('user_id', uid)
          .ilike('title', '%$lower%')
          .limit(5);
      for (final r in reminders) {
        final done = r['is_done'] as bool? ?? false;
        results.add(_SearchResult(
          icon: Icons.alarm_rounded,
          color: AppColors.warning,
          title: r['title'] as String,
          subtitle: 'Lembrete · ${AppFormatters.formatDate(DateTime.parse(r['due_date']))}${done ? ' · Concluído' : ''}',
          category: 'Lembretes',
          onTap: (ctx) => ctx.push('/reminders/edit/${r['id']}'),
        ));
      }

      // Pessoas
      final people = await supabase
          .from('people')
          .select('id, name, relationship')
          .eq('user_id', uid)
          .ilike('name', '%$lower%')
          .limit(5);
      for (final p in people) {
        results.add(_SearchResult(
          icon: Icons.person_rounded,
          color: const Color(0xFF8B5CF6),
          title: p['name'] as String,
          subtitle: 'Pessoa · ${p['relationship'] ?? ''}',
          category: 'Pessoas',
          onTap: (ctx) => ctx.push('/people/edit/${p['id']}'),
        ));
      }

      // Datas especiais
      final dates = await supabase
          .from('special_dates')
          .select('id, title, type, day, month')
          .eq('user_id', uid)
          .ilike('title', '%$lower%')
          .limit(5);
      for (final d in dates) {
        final day = d['day'] as int;
        final month = d['month'] as int;
        results.add(_SearchResult(
          icon: Icons.cake_rounded,
          color: const Color(0xFFEC4899),
          title: d['title'] as String,
          subtitle: 'Data especial · ${d['type']} · $day/${month.toString().padLeft(2, '0')}',
          category: 'Datas Especiais',
          onTap: (ctx) => ctx.go('/people'),
        ));
      }

      // Medicamentos
      final meds = await supabase
          .from('medications')
          .select('id, name, dosage')
          .eq('user_id', uid)
          .ilike('name', '%$lower%')
          .limit(5);
      for (final m in meds) {
        results.add(_SearchResult(
          icon: Icons.medication_rounded,
          color: AppColors.error,
          title: m['name'] as String,
          subtitle: 'Medicamento · ${m['dosage'] ?? ''}',
          category: 'Medicamentos',
          onTap: (ctx) => ctx.push('/health/medication/edit/${m['id']}'),
        ));
      }

      // Lançamentos financeiros
      final entries = await supabase
          .from('financial_entries')
          .select('id, title, value, type, date')
          .eq('user_id', uid)
          .ilike('title', '%$lower%')
          .limit(5);
      for (final e in entries) {
        final val = (e['value'] as num).toDouble();
        final type = e['type'] as String;
        results.add(_SearchResult(
          icon: type == 'receita' ? Icons.trending_up_rounded : Icons.trending_down_rounded,
          color: type == 'receita' ? AppColors.greenMedium : AppColors.error,
          title: e['title'] as String,
          subtitle: 'Financeiro · ${AppFormatters.formatCurrency(val)} · ${AppFormatters.formatDate(DateTime.parse(e['date']))}',
          category: 'Financeiro',
          onTap: (ctx) => ctx.push('/financial/entry/edit/${e['id']}'),
        ));
      }

      // Documentos
      final docs = await supabase
          .from('documents')
          .select('id, title, type')
          .eq('user_id', uid)
          .ilike('title', '%$lower%')
          .limit(5);
      for (final d in docs) {
        results.add(_SearchResult(
          icon: Icons.folder_rounded,
          color: AppColors.greyDark,
          title: d['title'] as String,
          subtitle: 'Documento · ${d['type']}',
          category: 'Documentos',
          onTap: (ctx) => ctx.go('/documents'),
        ));
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _results = results;
        _loading = false;
      });
    }
  }

  Map<String, List<_SearchResult>> get _grouped {
    final map = <String, List<_SearchResult>>{};
    for (final r in _results) {
      map.putIfAbsent(r.category, () => []).add(r);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _grouped;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: TextField(
          controller: _searchCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Buscar compromissos, notas, pessoas...',
            border: InputBorder.none,
            filled: false,
          ),
        ),
        actions: [
          if (_searchCtrl.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_rounded),
              onPressed: () {
                _searchCtrl.clear();
                setState(() => _results = []);
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _searchCtrl.text.length < 2
              ? _buildHint()
              : _results.isEmpty
                  ? _buildEmpty()
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        for (final category in grouped.keys) ...[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8, top: 8),
                            child: Text(
                              category,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ),
                          AppCard(
                            padding: EdgeInsets.zero,
                            child: Column(
                              children: [
                                for (int i = 0; i < grouped[category]!.length; i++) ...[
                                  _ResultTile(result: grouped[category]![i]),
                                  if (i < grouped[category]!.length - 1)
                                    const Divider(height: 0, indent: 56),
                                ],
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 80),
                      ],
                    ),
    );
  }

  Widget _buildHint() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.greenLight.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search_rounded, size: 40, color: AppColors.greenMedium),
          ),
          const SizedBox(height: 16),
          Text(
            'Pesquise em todo o app',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Compromissos, notas, pessoas, medicamentos\ne muito mais em um só lugar.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off_rounded, size: 60, color: AppColors.greyMedium),
          const SizedBox(height: 16),
          Text(
            'Nenhum resultado encontrado',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Tente palavras diferentes.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _SearchResult {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String category;
  final void Function(BuildContext ctx) onTap;

  const _SearchResult({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.onTap,
  });
}

class _ResultTile extends StatelessWidget {
  final _SearchResult result;
  const _ResultTile({required this.result});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: result.color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(result.icon, color: result.color, size: 20),
      ),
      title: Text(result.title, style: Theme.of(context).textTheme.titleMedium),
      subtitle: Text(result.subtitle, style: const TextStyle(fontSize: 12, color: AppColors.greyMedium)),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.greyMedium),
      onTap: () => result.onTap(context),
    );
  }
}
