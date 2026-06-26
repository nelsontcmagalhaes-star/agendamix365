import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../core/models.dart';
import '../../core/supabase_service.dart';
import '../../shared/widgets/app_card.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  List<DocumentModel> _docs = [];
  bool _loading = true;
  String? _filterType;
  String _search = '';

  static const _docTypes = ['Pessoal', 'Receita médica', 'Exame', 'Nota fiscal', 'Garantia', 'Outros'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = SupabaseService.currentUserId;
    if (uid == null) return;
    final res = await supabase
        .from('documents')
        .select()
        .eq('user_id', uid)
        .order('created_at', ascending: false);

    if (mounted) {
      setState(() {
        _docs = (res as List).map((e) => DocumentModel.fromJson(e)).toList();
        _loading = false;
      });
    }
  }

  List<DocumentModel> get _filtered => _docs.where((d) {
    final matchSearch = _search.isEmpty || d.title.toLowerCase().contains(_search.toLowerCase());
    final matchType = _filterType == null || d.type == _filterType;
    return matchSearch && matchType;
  }).toList();

  IconData _typeIcon(String type) {
    switch (type) {
      case 'Receita médica': return Icons.medication_outlined;
      case 'Exame': return Icons.science_outlined;
      case 'Nota fiscal': return Icons.receipt_long_outlined;
      case 'Garantia': return Icons.verified_outlined;
      case 'Pessoal': return Icons.badge_outlined;
      default: return Icons.folder_outlined;
    }
  }

  Future<void> _addDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) return;

    final uid = SupabaseService.currentUserId!;
    final path = '$uid/${DateTime.now().millisecondsSinceEpoch}_${file.name}';
    final url = await SupabaseService.uploadFile(
      bucket: 'documents',
      path: path,
      bytes: file.bytes!,
    );

    if (url != null) {
      await supabase.from('documents').insert({
        'user_id': uid,
        'title': file.name,
        'type': 'Outros',
        'file_url': url,
      });
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Documentos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: _addDocument,
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
                hintText: 'Pesquisar documentos...',
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
                  label: 'Todos',
                  color: AppColors.greenMedium,
                  isSelected: _filterType == null,
                  onTap: () => setState(() => _filterType = null),
                ),
                const SizedBox(width: 8),
                ..._docTypes.map((t) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: CategoryChip(
                    label: t,
                    color: AppColors.greenMedium,
                    isSelected: _filterType == t,
                    onTap: () => setState(() => _filterType = _filterType == t ? null : t),
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
                        icon: Icons.folder_outlined,
                        title: 'Nenhum documento',
                        subtitle: 'Guarde PDFs, fotos, receitas e mais',
                        actionLabel: 'Adicionar documento',
                        onAction: _addDocument,
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.1,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: _filtered.length,
                        itemBuilder: (context, i) {
                          final doc = _filtered[i];
                          return _DocCard(doc: doc, typeIcon: _typeIcon(doc.type), onRefresh: _load);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _DocCard extends StatelessWidget {
  final DocumentModel doc;
  final IconData typeIcon;
  final VoidCallback onRefresh;

  const _DocCard({required this.doc, required this.typeIcon, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.greenLight.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(typeIcon, color: AppColors.greenMedium, size: 22),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _delete(context),
                child: const Icon(Icons.more_vert_rounded, color: AppColors.greyMedium, size: 18),
              ),
            ],
          ),
          const Spacer(),
          Text(
            doc.title,
            style: Theme.of(context).textTheme.titleMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            AppFormatters.formatDate(doc.createdAt),
            style: const TextStyle(fontSize: 11, color: AppColors.greyMedium),
          ),
        ],
      ),
    );
  }

  void _delete(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
            title: const Text('Excluir', style: TextStyle(color: AppColors.error)),
            onTap: () async {
              if (!SupabaseService.requirePremium(context)) return;
              await supabase.from('documents').delete().eq('id', doc.id);
              if (context.mounted) Navigator.pop(context);
              onRefresh();
            },
          ),
          ListTile(
            leading: const Icon(Icons.close_rounded),
            title: const Text('Cancelar'),
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
