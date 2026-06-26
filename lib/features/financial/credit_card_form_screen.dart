import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../core/models.dart';
import '../../core/supabase_service.dart';
import '../../shared/widgets/app_card.dart';

class CreditCardFormScreen extends StatefulWidget {
  final String? cardId;
  const CreditCardFormScreen({super.key, this.cardId});

  @override
  State<CreditCardFormScreen> createState() => _CreditCardFormScreenState();
}

class _CreditCardFormScreenState extends State<CreditCardFormScreen> {
  final _nameCtrl = TextEditingController();
  final _bankCtrl = TextEditingController();
  final _limitCtrl = TextEditingController();
  String _operator = 'Visa';
  int _closingDay = 1;
  int _dueDay = 10;
  bool _loading = false;

  static const _operators = ['Visa', 'Mastercard', 'Elo', 'American Express', 'Hipercard', 'Diners', 'Outros'];

  int get _bestBuyDay {
    final day = _closingDay + 1;
    return day > 28 ? 1 : day;
  }

  @override
  void initState() {
    super.initState();
    if (widget.cardId != null) _load();
  }

  Future<void> _load() async {
    final res = await supabase.from('credit_cards').select().eq('id', widget.cardId!).single();
    final c = CreditCardModel.fromJson(res);
    setState(() {
      _nameCtrl.text = c.name;
      _bankCtrl.text = c.bank;
      _operator = _operators.contains(c.operator) ? c.operator : 'Outros';
      _limitCtrl.text = c.limit.toStringAsFixed(2).replaceAll('.', ',');
      _closingDay = c.closingDay;
      _dueDay = c.dueDay;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bankCtrl.dispose();
    _limitCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty || _bankCtrl.text.trim().isEmpty) return;
    if (!SupabaseService.requirePremium(context)) return;
    setState(() => _loading = true);
    final limit = double.tryParse(_limitCtrl.text.replaceAll(',', '.')) ?? 0;
    final data = {
      'user_id': SupabaseService.currentUserId!,
      'name': _nameCtrl.text.trim(),
      'bank': _bankCtrl.text.trim(),
      'operator': _operator,
      'limit': limit,
      'closing_day': _closingDay,
      'due_day': _dueDay,
      'best_buy_day': _bestBuyDay,
    };
    try {
      if (widget.cardId != null) {
        await supabase.from('credit_cards').update(data).eq('id', widget.cardId!);
      } else {
        await supabase.from('credit_cards').insert(data);
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
        title: Text(widget.cardId != null ? 'Editar cartão' : 'Novo cartão'),
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
          Container(
            height: 120,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.greenMedium, AppColors.greenDark],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _nameCtrl.text.isEmpty ? 'Nome do cartão' : _nameCtrl.text,
                  style: const TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.w700),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_bankCtrl.text.isEmpty ? 'Banco' : _bankCtrl.text,
                        style: TextStyle(color: AppColors.white.withOpacity(0.8))),
                    const Icon(Icons.credit_card_rounded, color: AppColors.white, size: 28),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              children: [
                TextField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Nome do cartão (ex: Nubank Gold)',
                    border: InputBorder.none,
                    filled: false,
                    prefixIcon: Icon(Icons.credit_card_outlined, color: AppColors.greyMedium),
                  ),
                ),
                const Divider(height: 0),
                TextField(
                  controller: _bankCtrl,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Banco (ex: Nubank)',
                    border: InputBorder.none,
                    filled: false,
                    prefixIcon: Icon(Icons.account_balance_outlined, color: AppColors.greyMedium),
                  ),
                ),
                const Divider(height: 0),
                DropdownButtonFormField<String>(
                  value: _operator,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    filled: false,
                    prefixIcon: Icon(Icons.payment_rounded, color: AppColors.greyMedium),
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  items: _operators.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
                  onChanged: (v) => setState(() => _operator = v!),
                ),
                const Divider(height: 0),
                TextField(
                  controller: _limitCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    hintText: 'Limite',
                    border: InputBorder.none,
                    filled: false,
                    prefixText: 'R\$ ',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              children: [
                _DayPicker(label: 'Dia de fechamento', value: _closingDay, onChange: (v) => setState(() => _closingDay = v)),
                const Divider(height: 0),
                _DayPicker(label: 'Dia de vencimento', value: _dueDay, onChange: (v) => setState(() => _dueDay = v)),
                const Divider(height: 0),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Melhor dia de compra'),
                  subtitle: const Text('Calculado automaticamente'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.greenLight.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Dia $_bestBuyDay', style: const TextStyle(color: AppColors.greenDark, fontWeight: FontWeight.w700)),
                  ),
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

class _DayPicker extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChange;

  const _DayPicker({required this.label, required this.value, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: DropdownButton<int>(
        value: value,
        underline: const SizedBox(),
        items: List.generate(28, (i) => DropdownMenuItem(value: i + 1, child: Text('Dia ${i + 1}'))),
        onChanged: (v) => onChange(v!),
      ),
    );
  }
}
