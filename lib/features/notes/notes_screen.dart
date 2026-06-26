import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../core/models.dart';
import '../../core/supabase_service.dart';
import '../../shared/widgets/app_card.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List<NoteModel> _notes = [];
  bool _loading = true;
  String _search = '';
  String? _filterCategory;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = SupabaseService.currentUserId;
    if (uid == null) return;
    final res = await supabase
        .from('notes')
        .select()
        .eq('user_id', uid)
        .order('is_pinned', ascending: false)
        .order('updated_at', ascending: false);

    if (mounted) {
      setState(() {
        _notes = (res as List).map((e) => NoteModel.fromJson(e)).toList();
        _loading = false;
      });
    }
  }

  List<NoteModel> get _filtered {
    return _notes.where((n) {
      final matchSearch = _search.isEmpty ||
          n.title.toLowerCase().contains(_search.toLowerCase()) ||
          n.content.toLowerCase().contains(_search.toLowerCase());
      final matchCat = _filterCategory == null || n.category == _filterCategory;
      return matchSearch && matchCat;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Anotações'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.push('/notes/new').then((_) => _load()),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: const InputDecoration(
                hintText: 'Pesquisar anotações...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                CategoryChip(
                  label: 'Todas',
                  color: AppColors.greenMedium,
                  isSelected: _filterCategory == null,
                  onTap: () => setState(() => _filterCategory = null),
                ),
                const SizedBox(width: 8),
                ...AppCategories.notes.map((c) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: CategoryChip(
                    label: c,
                    color: AppColors.greenMedium,
                    isSelected: _filterCategory == c,
                    onTap: () => setState(() => _filterCategory = _filterCategory == c ? null : c),
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? EmptyState(
                        icon: Icons.note_alt_outlined,
                        title: 'Nenhuma anotação',
                        actionLabel: 'Nova anotação',
                        onAction: () => context.push('/notes/new').then((_) => _load()),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                        itemCount: _filtered.length,
                        itemBuilder: (context, i) {
                          final note = _filtered[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _NoteCard(note: note, onRefresh: _load),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final NoteModel note;
  final VoidCallback onRefresh;

  const _NoteCard({required this.note, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => context.push('/notes/edit/${note.id}').then((_) => onRefresh()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  note.title,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (note.isPinned)
                const Icon(Icons.push_pin_rounded, size: 16, color: AppColors.greenMedium),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => _delete(context),
                child: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.greyMedium),
              ),
            ],
          ),
          if (note.content.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              note.content,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.greenLight.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  note.category,
                  style: const TextStyle(fontSize: 10, color: AppColors.greenDark, fontWeight: FontWeight.w600),
                ),
              ),
              const Spacer(),
              Text(
                AppFormatters.formatDate(note.updatedAt),
                style: const TextStyle(fontSize: 11, color: AppColors.greyMedium),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _delete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir anotação'),
        content: Text('Deseja excluir "${note.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              if (!SupabaseService.requirePremium(context)) return;
              await supabase.from('notes').delete().eq('id', note.id);
              if (context.mounted) Navigator.pop(context);
              onRefresh();
            },
            child: const Text('Excluir', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
