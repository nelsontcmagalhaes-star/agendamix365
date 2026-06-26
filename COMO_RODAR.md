# AgendaMix 365 — Como rodar

## Pré-requisitos

1. **Flutter SDK** (versão 3.2+) — https://docs.flutter.dev/get-started/install
2. **Android Studio** com Android SDK
3. **Supabase** (já configurado)

## Passo 1 — Configurar o banco de dados

1. Acesse o painel do Supabase: https://supabase.com/dashboard
2. Vá em **SQL Editor**
3. Cole o conteúdo de `supabase_schema.sql` e execute

## Passo 2 — Instalar Flutter

Baixe em https://docs.flutter.dev/get-started/install/windows
Extraia e adicione `flutter/bin` ao PATH do Windows.

Verifique com:
```
flutter doctor
```

## Passo 3 — Instalar dependências

```bash
cd agendamix365
flutter pub get
```

## Passo 4 — Rodar no emulador ou dispositivo

```bash
# Listar dispositivos disponíveis
flutter devices

# Rodar no dispositivo
flutter run

# Gerar APK de release
flutter build apk --release
```

O APK gerado estará em: `build/app/outputs/flutter-apk/app-release.apk`

## Estrutura do projeto

```
lib/
├── main.dart                    # Ponto de entrada
├── core/
│   ├── constants.dart           # Cores, strings, tamanhos
│   ├── theme.dart               # Tema do app
│   ├── formatters.dart          # R$ 1.250,20, dd/MM/aaaa, HH:mm
│   ├── router.dart              # Rotas (go_router)
│   ├── models.dart              # Modelos de dados
│   └── supabase_service.dart    # Auth + client Supabase
├── features/
│   ├── auth/                    # Login, cadastro, recuperar senha
│   ├── home/                    # Tela "Meu Dia"
│   ├── agenda/                  # Calendário + compromissos
│   ├── notes/                   # Anotações
│   ├── reminders/               # Lembretes
│   ├── people/                  # Pessoas + datas especiais
│   ├── health/                  # Medicamentos + consultas
│   ├── financial/               # Receitas, despesas, cartões
│   ├── capture/                 # Captura por voz
│   └── documents/               # Arquivos, PDFs, fotos
└── shared/
    └── widgets/
        ├── main_scaffold.dart   # Nav bar + botão capturar
        └── app_card.dart        # Componentes reutilizáveis
```

## Funcionalidades

- ✅ Login / Cadastro / Recuperar senha
- ✅ Tela "Meu Dia" com saudação e resumo
- ✅ Agenda com calendário mensal/semanal
- ✅ Anotações com categorias e pesquisa
- ✅ Lembretes com alarme e data
- ✅ Pessoas e datas especiais (alertas automáticos)
- ✅ Saúde: medicamentos + consultas
- ✅ Financeiro: receitas, despesas, cartões de crédito
- ✅ Captura por voz (reconhece tipo automaticamente)
- ✅ Documentos: PDFs e fotos
- ✅ Pesquisa universal
- ✅ Formato R$ 1.250,20 e dd/MM/aaaa e HH:mm
- ✅ Integração Supabase + RLS por usuário
- ✅ Design verde claro/médio/escuro, cards arredondados
