import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../core/supabase_service.dart';
import '../../shared/widgets/app_card.dart';

bool _isValidEmail(String v) =>
    RegExp(r'^[\w._%+\-]+@[\w.\-]+\.[a-zA-Z]{2,}$').hasMatch(v.trim());

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _loading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _lgpdAccepted = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_lgpdAccepted) {
      setState(() => _error = 'Você deve aceitar a Política de Privacidade e LGPD para continuar.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await SupabaseService.signUp(_emailCtrl.text.trim(), _passCtrl.text, _nameCtrl.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conta criada! Verifique seu e-mail para confirmar.')),
        );
        context.go('/auth/login');
      }
    } catch (e) {
      setState(() { _error = 'Não foi possível criar sua conta. Verifique os dados e tente novamente.'; });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Criar conta', style: Theme.of(context).textTheme.displayMedium),
                const SizedBox(height: 8),
                Text('Preencha os dados abaixo para começar', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 32),
                // Nome
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: 'Seu nome completo',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe seu nome' : null,
                ),
                const SizedBox(height: 16),
                // E-mail
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: 'Seu e-mail',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Informe seu e-mail';
                    if (!_isValidEmail(v)) return 'E-mail inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Senha
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscurePass,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: 'Crie uma senha',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      tooltip: _obscurePass ? 'Mostrar senha' : 'Ocultar senha',
                      icon: Icon(_obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscurePass = !_obscurePass),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Crie uma senha';
                    if (v.length < 6) return 'Mínimo 6 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Confirmar senha
                TextFormField(
                  controller: _confirmPassCtrl,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _register(),
                  decoration: InputDecoration(
                    hintText: 'Confirme a senha',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      tooltip: _obscureConfirm ? 'Mostrar senha' : 'Ocultar senha',
                      icon: Icon(_obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Confirme sua senha';
                    if (v != _passCtrl.text) return 'As senhas não conferem';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                // LGPD
                Container(
                  decoration: BoxDecoration(
                    color: _lgpdAccepted
                        ? AppColors.greenLight.withOpacity(0.1)
                        : AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _lgpdAccepted ? AppColors.greenMedium : AppColors.greySoft,
                      width: 1.5,
                    ),
                  ),
                  child: CheckboxListTile(
                    value: _lgpdAccepted,
                    activeColor: AppColors.greenMedium,
                    onChanged: (v) => setState(() => _lgpdAccepted = v ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    title: RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        children: [
                          const TextSpan(text: 'Li e concordo com a '),
                          TextSpan(
                            text: 'Política de Privacidade',
                            style: const TextStyle(
                              color: AppColors.greenMedium,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => _showLgpdDialog(context),
                          ),
                          const TextSpan(
                            text: ' e autorizo o uso dos meus dados conforme a '
                                'Lei Geral de Proteção de Dados (LGPD — Lei nº 13.709/2018).',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                GradientButton(label: 'Criar conta', onTap: _register, isLoading: _loading),
                const AppFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLgpdDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Política de Privacidade e LGPD'),
        content: const SingleChildScrollView(
          child: Text(
            'O AgendaMix 365 coleta e armazena apenas os dados '
            'necessários para o funcionamento do aplicativo (nome, '
            'e-mail e conteúdo que você cadastrar).\n\n'
            'Seus dados são protegidos em conformidade com a Lei Geral '
            'de Proteção de Dados (LGPD — Lei nº 13.709/2018) e não '
            'são compartilhados com terceiros sem seu consentimento.\n\n'
            'Você pode solicitar a exclusão da sua conta e de todos os '
            'dados a qualquer momento pelo e-mail:\n'
            'nelsonassembler@gmail.com',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _lgpdAccepted = true);
            },
            child: const Text('Aceitar'),
          ),
        ],
      ),
    );
  }
}
