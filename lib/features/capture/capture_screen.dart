import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../core/constants.dart';
import '../../core/supabase_service.dart';
import '../../shared/widgets/app_card.dart';

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> with SingleTickerProviderStateMixin {
  final SpeechToText _speech = SpeechToText();
  final _textCtrl = TextEditingController();
  bool _isListening = false;
  bool _speechAvailable = false;
  bool _loading = false;
  String _partialText = '';
  _CaptureType? _detectedType;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onStatus: (s) {
        if (s == 'done' || s == 'notListening') {
          setState(() => _isListening = false);
          _analyze(_textCtrl.text);
        }
      },
    );
    setState(() {});
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _textCtrl.dispose();
    _speech.cancel();
    super.dispose();
  }

  Future<void> _toggleListen() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    } else {
      setState(() { _isListening = true; _textCtrl.clear(); _detectedType = null; });
      String _lastWords = '';
      await _speech.listen(
        onResult: (result) {
          _lastWords = result.recognizedWords;
          final text = result.recognizedWords;
          if (text.isNotEmpty) {
            _textCtrl.value = TextEditingValue(
              text: text,
              selection: TextSelection.collapsed(offset: text.length),
            );
            _analyze(text);
          }
        },
        localeId: 'pt-BR',
        cancelOnError: false,
        partialResults: false,
      );
    }
  }

  void _analyze(String text) {
    if (text.isEmpty) return;
    final lower = text.toLowerCase();

    if (lower.contains('lembr') || lower.contains('pagar') || lower.contains('não esquecer')) {
      setState(() => _detectedType = _CaptureType.reminder);
    } else if (lower.contains('consulta') || lower.contains('médico') || lower.contains('remédio') || lower.contains('hospital')) {
      setState(() => _detectedType = _CaptureType.health);
    } else if (lower.contains('comprei') || lower.contains('paguei') || lower.contains('cartão') || lower.contains('r\$')) {
      setState(() => _detectedType = _CaptureType.financial);
    } else if (lower.contains('aniversário') || lower.contains('casamento') || lower.contains('formatura')) {
      setState(() => _detectedType = _CaptureType.specialDate);
    } else if (lower.contains('reunião') || lower.contains('compromisso') || lower.contains('às') && lower.contains('horas')) {
      setState(() => _detectedType = _CaptureType.appointment);
    } else {
      setState(() => _detectedType = _CaptureType.note);
    }
  }

  Future<void> _save() async {
    if (_textCtrl.text.trim().isEmpty || _detectedType == null) return;
    if (!SupabaseService.requirePremium(context)) return;
    setState(() => _loading = true);
    final uid = SupabaseService.currentUserId!;
    final text = _textCtrl.text.trim();

    try {
      switch (_detectedType!) {
        case _CaptureType.reminder:
          await supabase.from('reminders').insert({
            'user_id': uid,
            'title': text,
            'due_date': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
            'alarm_enabled': true,
            'is_done': false,
          });
          break;
        case _CaptureType.note:
          await supabase.from('notes').insert({
            'user_id': uid,
            'title': text.length > 40 ? '${text.substring(0, 40)}...' : text,
            'content': text,
            'category': 'Pessoal',
            'is_pinned': false,
            'updated_at': DateTime.now().toIso8601String(),
          });
          break;
        case _CaptureType.appointment:
          await supabase.from('appointments').insert({
            'user_id': uid,
            'title': text.length > 40 ? '${text.substring(0, 40)}...' : text,
            'start_time': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
            'category': 'Pessoal',
            'notify_enabled': true,
            'notify_minutes_before': 30,
          });
          break;
        case _CaptureType.financial:
          await supabase.from('financial_entries').insert({
            'user_id': uid,
            'title': text.length > 40 ? '${text.substring(0, 40)}...' : text,
            'value': 0.0,
            'type': 'despesa',
            'category': 'Outros',
            'date': DateTime.now().toIso8601String(),
            'is_paid': true,
          });
          break;
        case _CaptureType.health:
          await supabase.from('health_appointments').insert({
            'user_id': uid,
            'title': text.length > 40 ? '${text.substring(0, 40)}...' : text,
            'appointment_date': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
            'coverage_type': 'Particular',
          });
          break;
        case _CaptureType.specialDate:
          await supabase.from('special_dates').insert({
            'user_id': uid,
            'title': text.length > 40 ? '${text.substring(0, 40)}...' : text,
            'type': 'Aniversário',
            'day': DateTime.now().day,
            'month': DateTime.now().month,
            'alert_enabled': true,
          });
          break;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Salvo como ${_detectedType!.label}!')),
        );
        context.pop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao salvar. Tente novamente.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.textPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text('Capturar', style: TextStyle(color: AppColors.white)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Text(
                'Toque no microfone e fale!',
                style: Theme.of(context).textTheme.headlineMedium!.copyWith(color: AppColors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Eu entendo o que você precisa.',
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: AppColors.greyMedium),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              GestureDetector(
                onTap: _speechAvailable ? _toggleListen : null,
                child: AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, __) => Transform.scale(
                    scale: _isListening ? _pulse.value : 1.0,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: _isListening
                              ? [AppColors.error, AppColors.error.withOpacity(0.7)]
                              : [AppColors.greenLight, AppColors.greenDark],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (_isListening ? AppColors.error : AppColors.greenMedium).withOpacity(0.5),
                            blurRadius: 30,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                        color: AppColors.white,
                        size: 56,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _isListening ? 'Ouvindo...' : _speechAvailable ? 'Toque para falar' : 'Microfone não disponível',
                style: TextStyle(
                  color: _isListening ? AppColors.error : AppColors.greyMedium,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: AppCard(
                  color: AppColors.white.withOpacity(0.08),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _isListening
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.hearing_rounded, color: AppColors.greenLight, size: 32),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Ouvindo... fale agora',
                                      style: const TextStyle(color: AppColors.greyMedium, fontSize: 15, fontStyle: FontStyle.italic),
                                    ),
                                  ],
                                ),
                              )
                            : TextField(
                                controller: _textCtrl,
                                maxLines: null,
                                expands: true,
                                onChanged: _analyze,
                                style: const TextStyle(color: AppColors.white, fontSize: 16),
                                decoration: const InputDecoration(
                                  hintText: 'Ou escreva aqui...',
                                  hintStyle: TextStyle(color: AppColors.greyMedium),
                                  border: InputBorder.none,
                                  filled: false,
                                ),
                              ),
                      ),
                      if (_detectedType != null) ...[
                        const Divider(color: AppColors.greyDark),
                        _DetectedTypeChip(type: _detectedType!),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_detectedType != null)
                SizedBox(
                  width: double.infinity,
                  child: GradientButton(
                    label: 'Salvar como ${_detectedType!.label}',
                    onTap: _save,
                    isLoading: _loading,
                  ),
                ),
              const SizedBox(height: 8),
              _buildExamples(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExamples() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Exemplos:', style: TextStyle(color: AppColors.greyMedium, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        ...[
          '"Lembrar de pagar o condomínio dia 5"',
          '"Consulta com cardiologista terça às 9h"',
          '"Aniversário de Maria dia 20 de agosto"',
        ].map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(e, style: const TextStyle(color: AppColors.greyMedium, fontSize: 11)),
        )),
      ],
    );
  }
}

class _DetectedTypeChip extends StatelessWidget {
  final _CaptureType type;
  const _DetectedTypeChip({required this.type});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(type.icon, color: AppColors.greenLight, size: 16),
          const SizedBox(width: 6),
          Text(
            'Identificado como: ${type.label}',
            style: const TextStyle(color: AppColors.greenLight, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

enum _CaptureType {
  reminder('Lembrete', Icons.alarm_rounded),
  note('Anotação', Icons.note_rounded),
  appointment('Compromisso', Icons.event_rounded),
  financial('Despesa', Icons.account_balance_wallet_rounded),
  health('Saúde', Icons.favorite_rounded),
  specialDate('Data especial', Icons.cake_rounded);

  final String label;
  final IconData icon;

  const _CaptureType(this.label, this.icon);
}
