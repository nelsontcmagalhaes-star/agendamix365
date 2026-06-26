import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../core/models.dart';
import '../../core/supabase_service.dart';
import '../../shared/widgets/app_card.dart';

class FinancialScreen extends StatefulWidget {
  const FinancialScreen({super.key});

  @override
  State<FinancialScreen> createState() => _FinancialScreenState();
}

class _FinancialScreenState extends State<FinancialScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<FinancialEntryModel> _entries = [];
  List<CreditCardModel> _cards = [];
  bool _loading = true;

  double get _totalIncome => _entries.where((e) => e.type == 'receita').fold(0, (s, e) => s + e.value);
  double get _totalExpense => _entries.where((e) => e.type == 'despesa').fold(0, (s, e) => s + e.value);
  double get _balance => _totalIncome - _totalExpense;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
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

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 1);

    final [entriesRes, cardsRes] = await Future.wait([
      supabase
          .from('financial_entries')
          .select()
          .eq('user_id', uid)
          .gte('date', monthStart.toIso8601String())
          .lt('date', monthEnd.toIso8601String())
          .order('date', ascending: false),
      supabase.from('credit_cards').select().eq('user_id', uid).order('name'),
    ]);

    if (mounted) {
      setState(() {
        _entries = (entriesRes as List).map((e) => FinancialEntryModel.fromJson(e)).toList();
        _cards = (cardsRes as List).map((e) => CreditCardModel.fromJson(e)).toList();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Financeiro'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () {
              if (_tab.index == 2) {
                context.push('/financial/card/new').then((_) => _load());
              } else {
                context.push('/financial/entry/new').then((_) => _load());
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSummary(),
          TabBar(
            controller: _tab,
            labelColor: AppColors.greenMedium,
            unselectedLabelColor: AppColors.greyMedium,
            indicatorColor: AppColors.greenMedium,
            tabs: const [
              Tab(text: 'Tudo'),
              Tab(text: 'Despesas'),
              Tab(text: 'Cartões'),
            ],
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tab,
                    children: [
                      _EntriesTab(entries: _entries, onRefresh: _load),
                      _EntriesTab(entries: _entries.where((e) => e.type == 'despesa').toList(), onRefresh: _load),
                      _CardsTab(cards: _cards, onRefresh: _load),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.white,
      child: Row(
        children: [
          _SummaryCard(
            label: 'Receitas',
            value: _totalIncome,
            color: AppColors.greenMedium,
            icon: Icons.trending_up_rounded,
          ),
          const SizedBox(width: 8),
          _SummaryCard(
            label: 'Despesas',
            value: _totalExpense,
            color: AppColors.error,
            icon: Icons.trending_down_rounded,
          ),
          const SizedBox(width: 8),
          _SummaryCard(
            label: 'Saldo',
            value: _balance,
            color: _balance >= 0 ? AppColors.greenMedium : AppColors.error,
            icon: Icons.account_balance_rounded,
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final IconData icon;

  const _SummaryCard({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.greyMedium, fontWeight: FontWeight.w600)),
            Text(
              AppFormatters.formatCurrency(value),
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _EntriesTab extends StatelessWidget {
  final List<FinancialEntryModel> entries;
  final VoidCallback onRefresh;

  const _EntriesTab({required this.entries, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'Nenhum lançamento',
        subtitle: 'Registre suas receitas e despesas',
        actionLabel: 'Novo lançamento',
        onAction: () => context.push('/financial/entry/new').then((_) => onRefresh()),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: entries.length,
      itemBuilder: (context, i) {
        final entry = entries[i];
        final isIncome = entry.type == 'receita';
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: AppCard(
            onTap: () => context.push('/financial/entry/edit/${entry.id}').then((_) => onRefresh()),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isIncome ? AppColors.greenLight.withOpacity(0.15) : AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isIncome ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                    color: isIncome ? AppColors.greenMedium : AppColors.error,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.title, style: Theme.of(context).textTheme.titleMedium),
                      Text(
                        '${entry.category} • ${AppFormatters.formatDate(entry.date)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      AppFormatters.formatCurrency(entry.value),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isIncome ? AppColors.greenMedium : AppColors.error,
                      ),
                    ),
                    if (entry.installments != null && entry.installments! > 1)
                      Text(
                        '${entry.currentInstallment}/${entry.installments}x',
                        style: const TextStyle(fontSize: 11, color: AppColors.greyMedium),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CardsTab extends StatelessWidget {
  final List<CreditCardModel> cards;
  final VoidCallback onRefresh;

  const _CardsTab({required this.cards, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return EmptyState(
        icon: Icons.credit_card_outlined,
        title: 'Nenhum cartão',
        actionLabel: 'Adicionar cartão',
        onAction: () => context.push('/financial/card/new').then((_) => onRefresh()),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: cards.length,
      itemBuilder: (context, i) {
        final card = cards[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AppCard(
            onTap: () => context.push('/financial/card/edit/${card.id}').then((_) => onRefresh()),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.greenMedium, AppColors.greenDark],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(card.name, style: const TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                            Text(card.bank, style: TextStyle(color: AppColors.white.withOpacity(0.8), fontSize: 12)),
                          ],
                        ),
                      ),
                      const Icon(Icons.credit_card_rounded, color: AppColors.white, size: 32),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _CardInfo(label: 'Limite', value: AppFormatters.formatCurrency(card.limit)),
                    _CardInfo(label: 'Fechamento', value: 'Dia ${card.closingDay}'),
                    _CardInfo(label: 'Vencimento', value: 'Dia ${card.dueDay}'),
                    _CardInfo(label: 'Melhor dia', value: 'Dia ${card.bestBuyDay}'),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CardInfo extends StatelessWidget {
  final String label;
  final String value;

  const _CardInfo({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 9, color: AppColors.greyMedium, fontWeight: FontWeight.w600)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
