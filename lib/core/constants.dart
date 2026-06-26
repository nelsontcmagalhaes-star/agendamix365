import 'package:flutter/material.dart';

class AppColors {
  static const greenLight = Color(0xFF48D597);
  static const greenMedium = Color(0xFF2FC07E);
  static const greenDark = Color(0xFF1E9C65);
  static const background = Color(0xFFF5F7F8);
  static const white = Color(0xFFFFFFFF);
  static const greySoft = Color(0xFFE9ECEF);
  static const greyMedium = Color(0xFF9CA3AF);
  static const greyDark = Color(0xFF374151);
  static const textPrimary = Color(0xFF1A1A2E);
  static const textSecondary = Color(0xFF6B7280);
  static const error = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);
  static const info = Color(0xFF3B82F6);

  static const categoryColors = [
    Color(0xFF48D597),
    Color(0xFF3B82F6),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFF06B6D4),
    Color(0xFF84CC16),
  ];
}

class AppStrings {
  static const appName = 'AgendaMix 365';
  static const slogan = 'Sua vida organizada. Todos os dias do ano.';
  static const concept = 'Uma agenda simples por fora. Um assistente inteligente por dentro.';

  static const supabaseUrl = 'https://iuuxvohgdxuxonnpejee.supabase.co';
  static const supabaseAnonKey = 'sb_publishable_lwS18tPWHlwpClMepjHnrw_NQkcFDfz';

  // Acesso premium
  static const premiumEmail = 'nelsontcmagalhaes@gmail.com';

  // Rodapé
  static const devName = 'Nelson Tomaz Catunda Magalhães';
  static const devEmail = 'nelsonassembler@gmail.com';
  static const copyright = '© 2026 Todos os direitos reservados';
}

class AppSizes {
  static const radiusSmall = 8.0;
  static const radiusMedium = 16.0;
  static const radiusLarge = 24.0;
  static const radiusXLarge = 32.0;
  static const paddingSmall = 8.0;
  static const paddingMedium = 16.0;
  static const paddingLarge = 24.0;
}

class AppCategories {
  static const appointment = [
    'Trabalho',
    'Pessoal',
    'Saúde',
    'Família',
    'Social',
    'Estudo',
    'Outros',
  ];

  static const notes = [
    'Ideia',
    'Trabalho',
    'Pessoal',
    'Receita',
    'Viagem',
    'Outros',
  ];

  static const relationship = [
    'Cônjuge',
    'Filho(a)',
    'Pai',
    'Mãe',
    'Irmão(ã)',
    'Avô/Avó',
    'Tio(a)',
    'Primo(a)',
    'Amigo(a)',
    'Colega',
    'Outros',
  ];

  static const specialDateType = [
    'Aniversário',
    'Casamento',
    'Batizado',
    'Formatura',
    'Outro',
  ];
}
