import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants.dart';
import '../../core/models.dart';
import '../../core/supabase_service.dart';
import '../../shared/widgets/app_card.dart';

class PersonFormScreen extends StatefulWidget {
  final String? personId;
  const PersonFormScreen({super.key, this.personId});

  @override
  State<PersonFormScreen> createState() => _PersonFormScreenState();
}

class _PersonFormScreenState extends State<PersonFormScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _giftsCtrl = TextEditingController();
  String _relationship = 'Amigo(a)';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.personId != null) _load();
  }

  Future<void> _load() async {
    final res = await supabase.from('people').select().eq('id', widget.personId!).single();
    final p = PersonModel.fromJson(res);
    setState(() {
      _nameCtrl.text = p.name;
      _phoneCtrl.text = p.phone ?? '';
      _whatsappCtrl.text = p.whatsapp ?? '';
      _emailCtrl.text = p.email ?? '';
      _addressCtrl.text = p.address ?? '';
      _notesCtrl.text = p.notes ?? '';
      _giftsCtrl.text = p.giftIdeas ?? '';
      _relationship = p.relationship ?? 'Amigo(a)';
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _whatsappCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    _giftsCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    if (!SupabaseService.requirePremium(context)) return;
    setState(() => _loading = true);
    final data = {
      'user_id': SupabaseService.currentUserId!,
      'name': _nameCtrl.text.trim(),
      'relationship': _relationship,
      'phone': _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      'whatsapp': _whatsappCtrl.text.trim().isEmpty ? null : _whatsappCtrl.text.trim(),
      'email': _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      'address': _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      'gift_ideas': _giftsCtrl.text.trim().isEmpty ? null : _giftsCtrl.text.trim(),
    };
    try {
      if (widget.personId != null) {
        await supabase.from('people').update(data).eq('id', widget.personId!);
      } else {
        await supabase.from('people').insert(data);
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
        title: Text(widget.personId != null ? 'Editar pessoa' : 'Nova pessoa'),
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
            child: Column(
              children: [
                TextField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'Nome completo',
                    border: InputBorder.none,
                    filled: false,
                    prefixIcon: Icon(Icons.person_outline, color: AppColors.greyMedium),
                  ),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Divider(),
                DropdownButtonFormField<String>(
                  value: _relationship,
                  decoration: const InputDecoration(
                    labelText: 'Parentesco/Relação',
                    border: InputBorder.none,
                    filled: false,
                  ),
                  items: AppCategories.relationship.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (v) => setState(() => _relationship = v!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              children: [
                _FieldRow(icon: Icons.phone_outlined, label: 'Telefone', controller: _phoneCtrl, keyboardType: TextInputType.phone),
                const Divider(height: 0),
                _WhatsAppFieldRow(controller: _whatsappCtrl),
                const Divider(height: 0),
                _FieldRow(icon: Icons.email_outlined, label: 'E-mail', controller: _emailCtrl, keyboardType: TextInputType.emailAddress),
                const Divider(height: 0),
                _FieldRow(icon: Icons.location_on_outlined, label: 'Endereço', controller: _addressCtrl),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('Ideias de presentes', style: Theme.of(context).textTheme.titleMedium),
                ),
                TextField(
                  controller: _giftsCtrl,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'O que essa pessoa gosta? Ideias de presente...',
                    border: InputBorder.none,
                    filled: false,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: TextField(
              controller: _notesCtrl,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Observações sobre essa pessoa...',
                border: InputBorder.none,
                filled: false,
              ),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  const _FieldRow({required this.icon, required this.label, required this.controller, this.keyboardType});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: label,
        border: InputBorder.none,
        filled: false,
        prefixIcon: Icon(icon, color: AppColors.greyMedium, size: 20),
      ),
    );
  }
}

class _WhatsAppFieldRow extends StatelessWidget {
  final TextEditingController controller;
  const _WhatsAppFieldRow({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final hasNumber = value.text.trim().isNotEmpty;
        return Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: 'WhatsApp',
                  border: InputBorder.none,
                  filled: false,
                  prefixIcon: Icon(Icons.chat_outlined, color: AppColors.greyMedium, size: 20),
                ),
              ),
            ),
            if (hasNumber)
              IconButton(
                icon: const Icon(Icons.open_in_new_rounded, color: Color(0xFF25D366), size: 20),
                tooltip: 'Abrir no WhatsApp',
                onPressed: () {
                  final number = value.text.trim().replaceAll(RegExp(r'[^\d+]'), '');
                  final url = 'https://wa.me/$number';
                  launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                },
              ),
          ],
        );
      },
    );
  }
}
