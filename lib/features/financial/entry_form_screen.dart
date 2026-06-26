import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../core/models.dart';
import '../../core/supabase_service.dart';
import '../../shared/widgets/app_card.dart';

class EntryFormScreen extends StatefulWidget {
  final String? entryId;
  const EntryFormScreen({super.key, this.entryId});

  @override
  State<EntryFormScreen> createState() => _EntryFormScreenState();
}

class _EntryFormScreenState extends State<EntryFormScreen> {
  final _titleCtrl = TextEditingController();
  final _valueCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _type = 'despesa';
  String _category = 'Outros';
  DateTime _date = DateTime.now();
  bool _isPaid = false;
  int? _installments;
  String? _creditCardId;
  List<Map<String, dynamic>> _cards = [];
  bool _loading = false;

  static const _incomeCategories = ['Salário', 'Freelance', 'Investimento', 'Outros'];
  static const _expenseCategories = ['Alimentação', 'Transporte', 'Saúde', 'Lazer', 'Educação', 'Moradia', 'Roupas', 'Outros'];

  List<String> get _categories => _type == 'receita' ? _incomeCategories : _expenseCategories;

  @override
  void initState() {
    super.initState();
    _loadCards();
    if (widget.entryId != null) _load();
  }

  Future<void> _loadCards() async {
    final uid = SupabaseService.currentUserId;
    if (uid == null) return;
    try {
      final res = await supabase
          .from('credit_cards')
          .select('id, name, bank')
          .eq('user_id', uid)
          .order('name');
      if (mounted) {
        setState(() => _cards = List<Map<String, dynamic>>.from(res));
      }
    } catch (_) {}
  }

  Future<void> _load() async {
    final res = await supabase.from('financial_entries').select().eq('id', widget.entryId!).single();
    final e = FinancialEntryModel.fromJson(res);
    setState(() {
      _titleCtrl.text = e.title;
      _valueCtrl.text = e.value.toStringAsFixed(2).replaceAll('.', ',');
      _notesCtrl.text = e.notes ?? '';
      _type = e.type;
      _category = e.category;
      _date = e.date;
      _isPaid = e.isPaid;
      _installments = e.installments;
      _creditCardId = e.creditCardId;
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _valueCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty || _valueCtrl.text.trim().isEmpty) return;
    if (!SupabaseService.requirePremium(context)) return;
    setState(() => _loading = true);
    final value = double.tryParse(_valueCtrl.text.replaceAll(',', '.')) ?? 0;
    final data = {
      'user_id': SupabaseService.currentUserId!,
      'title': _titleCtrl.text.trim(),
      'value': value,
      'type': _type,
      'category': _category,
      'date': _date.toIso8601String(),
      'is_paid': _isPaid,
      'installments': _installments,
      'credit_card_id': _creditCardId,
      'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    };
    try {
      if (widget.entryId != null) {
        await supabase.from('financial_entries').update(data).eq('id', widget.entryId!);
      } else {
        await supabase.from('financial_entries').insert(data);
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
        title: Text(widget.entryId != null ? 'Editar lançamento' : 'Novo lançamento'),
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
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() { _type = 'despesa'; _category = 'Outros'; }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _type == 'despesa' ? AppColors.error.withOpacity(0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.trending_down_rounded, color: _type == 'despesa' ? AppColors.error : AppColors.greyMedium),
                          Text('Despesa', style: TextStyle(color: _type == 'despesa' ? AppColors.error : AppColors.greyMedium, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() { _type = 'receita'; _category = 'Outros'; }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _type == 'receita' ? AppColors.greenLight.withOpacity(0.2) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.trending_up_rounded, color: _type == 'receita' ? AppColors.greenMedium : AppColors.greyMedium),
                          Text('Receita', style: TextStyle(color: _type == 'receita' ? AppColors.greenMedium : AppColors.greyMedium, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              children: [
                TextField(
                  controller: _titleCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Descrição',
                    border: InputBorder.none,
                    filled: false,
                  ),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Divider(),
                TextField(
                  controller: _valueCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    hintText: '0,00',
                    border: InputBorder.none,
                    filled: false,
                    prefixText: 'R\$ ',
                    prefixStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
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
                  children: _categories.map((c) => CategoryChip(
                    label: c,
                    color: _type == 'receita' ? AppColors.greenMedium : AppColors.error,
                    isSelected: _category == c,
                    onTap: () => setState(() => _category = c),
                  )).toList(),
                ),
              ],
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
                      AppFormatters.formatDate(_date),
                      style: const TextStyle(color: AppColors.greenMedium, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const Divider(height: 0),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Pago'),
                  value: _isPaid,
                  activeColor: AppColors.greenMedium,
                  onChanged: (v) => setState(() => _isPaid = v),
                ),
                if (_type == 'despesa') ...[
                  const Divider(height: 0),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.credit_card_outlined, color: AppColors.greenMedium),
                    title: const Text('Parcelado'),
                    trailing: DropdownButton<int?>(
                      value: _installments,
                      underline: const SizedBox(),
                      hint: const Text('À vista'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('À vista')),
                        ...List.generate(24, (i) => DropdownMenuItem(value: i + 2, child: Text('${i + 2}x'))),
                      ],
                      onChanged: (v) => setState(() => _installments = v),
                    ),
                  ),
                  if (_cards.isNotEmpty) ...[
                    const Divider(height: 0),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.payment_rounded, color: AppColors.greenMedium),
                      title: const Text('Cartão de crédito'),
                      trailing: DropdownButton<String?>(
                        value: _creditCardId,
                        underline: const SizedBox(),
                        hint: const Text('Nenhum'),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Nenhum')),
                          ..._cards.map((c) => DropdownMenuItem(
                            value: c['id'] as String,
                            child: Text('${c['name']} (${c['bank']})'),
                          )),
                        ],
                        onChanged: (v) => setState(() => _creditCardId = v),
                      ),
                    ),
                  ],
                ],
              ],
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
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null) setState(() => _date = picked);
  }
}
