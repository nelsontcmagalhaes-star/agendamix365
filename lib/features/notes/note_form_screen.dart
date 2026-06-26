import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../core/models.dart';
import '../../core/supabase_service.dart';
import '../../shared/widgets/app_card.dart';

class NoteFormScreen extends StatefulWidget {
  final String? noteId;
  const NoteFormScreen({super.key, this.noteId});

  @override
  State<NoteFormScreen> createState() => _NoteFormScreenState();
}

class _NoteFormScreenState extends State<NoteFormScreen> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  String _category = 'Pessoal';
  bool _isPinned = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.noteId != null) _load();
  }

  Future<void> _load() async {
    final res = await supabase.from('notes').select().eq('id', widget.noteId!).single();
    final note = NoteModel.fromJson(res);
    setState(() {
      _titleCtrl.text = note.title;
      _contentCtrl.text = note.content;
      _category = note.category;
      _isPinned = note.isPinned;
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um título para a nota')),
      );
      return;
    }
    if (!SupabaseService.requirePremium(context)) return;
    setState(() => _loading = true);
    final uid = SupabaseService.currentUserId!;
    final data = {
      'user_id': uid,
      'title': _titleCtrl.text.trim(),
      'content': _contentCtrl.text.trim(),
      'category': _category,
      'is_pinned': _isPinned,
      'updated_at': DateTime.now().toIso8601String(),
    };

    try {
      if (widget.noteId != null) {
        await supabase.from('notes').update(data).eq('id', widget.noteId!);
      } else {
        await supabase.from('notes').insert(data);
      }
      if (mounted) context.pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao salvar nota')),
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
        title: Text(widget.noteId != null ? 'Editar nota' : 'Nova nota'),
        leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => context.pop()),
        actions: [
          IconButton(
            icon: Icon(_isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                color: _isPinned ? AppColors.greenMedium : null),
            onPressed: () => setState(() => _isPinned = !_isPinned),
          ),
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
                  controller: _titleCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Título',
                    border: InputBorder.none,
                    filled: false,
                  ),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Divider(),
                TextField(
                  controller: _contentCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 12,
                  decoration: const InputDecoration(
                    hintText: 'Escreva sua anotação aqui...',
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
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text('Categoria', style: Theme.of(context).textTheme.titleMedium),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppCategories.notes.map((c) => CategoryChip(
                    label: c,
                    color: AppColors.greenMedium,
                    isSelected: _category == c,
                    onTap: () => setState(() => _category = c),
                  )).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
