import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/auth/forgot_password_screen.dart';
import '../features/auth/reset_password_screen.dart';
import '../features/home/home_screen.dart';
import '../features/agenda/agenda_screen.dart';
import '../features/agenda/appointment_form_screen.dart';
import '../features/notes/notes_screen.dart';
import '../features/notes/note_form_screen.dart';
import '../features/reminders/reminders_screen.dart';
import '../features/reminders/reminder_form_screen.dart';
import '../features/people/people_screen.dart';
import '../features/people/person_form_screen.dart';
import '../features/health/health_screen.dart';
import '../features/health/medication_form_screen.dart';
import '../features/health/appointment_health_form_screen.dart';
import '../features/financial/financial_screen.dart';
import '../features/financial/entry_form_screen.dart';
import '../features/financial/credit_card_form_screen.dart';
import '../features/capture/capture_screen.dart';
import '../features/documents/documents_screen.dart';
import '../features/search/search_screen.dart';
import '../shared/widgets/main_scaffold.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  redirect: (context, state) {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      final isAuth = session != null;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');
      if (!isAuth && !isAuthRoute) return '/auth/login';
      if (isAuth && isAuthRoute) return '/';
      return null;
    } catch (_) {
      return '/auth/login';
    }
  },
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => MainScaffold(child: child),
      routes: [
        GoRoute(path: '/', builder: (c, s) => const HomeScreen()),
        GoRoute(path: '/agenda', builder: (c, s) => const AgendaScreen()),
        GoRoute(path: '/notes', builder: (c, s) => const NotesScreen()),
        GoRoute(path: '/reminders', builder: (c, s) => const RemindersScreen()),
        GoRoute(path: '/people', builder: (c, s) => const PeopleScreen()),
        GoRoute(path: '/health', builder: (c, s) => const HealthScreen()),
        GoRoute(path: '/financial', builder: (c, s) => const FinancialScreen()),
        GoRoute(path: '/documents', builder: (c, s) => const DocumentsScreen()),
      ],
    ),
    // Form routes that appear above the shell (no bottom nav bar)
    GoRoute(
      path: '/agenda/new',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (c, s) => const AppointmentFormScreen(),
    ),
    GoRoute(
      path: '/agenda/edit/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (c, s) => AppointmentFormScreen(appointmentId: s.pathParameters['id']),
    ),
    GoRoute(
      path: '/notes/new',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (c, s) => const NoteFormScreen(),
    ),
    GoRoute(
      path: '/notes/edit/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (c, s) => NoteFormScreen(noteId: s.pathParameters['id']),
    ),
    GoRoute(
      path: '/reminders/new',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (c, s) => const ReminderFormScreen(),
    ),
    GoRoute(
      path: '/reminders/edit/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (c, s) => ReminderFormScreen(reminderId: s.pathParameters['id']),
    ),
    GoRoute(
      path: '/people/new',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (c, s) => const PersonFormScreen(),
    ),
    GoRoute(
      path: '/people/edit/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (c, s) => PersonFormScreen(personId: s.pathParameters['id']),
    ),
    GoRoute(
      path: '/health/medication/new',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (c, s) => const MedicationFormScreen(),
    ),
    GoRoute(
      path: '/health/medication/edit/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (c, s) => MedicationFormScreen(medicationId: s.pathParameters['id']),
    ),
    GoRoute(
      path: '/health/appointment/new',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (c, s) => const AppointmentHealthFormScreen(),
    ),
    GoRoute(
      path: '/health/appointment/edit/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (c, s) => AppointmentHealthFormScreen(appointmentId: s.pathParameters['id']),
    ),
    GoRoute(
      path: '/financial/entry/new',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (c, s) => const EntryFormScreen(),
    ),
    GoRoute(
      path: '/financial/entry/edit/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (c, s) => EntryFormScreen(entryId: s.pathParameters['id']),
    ),
    GoRoute(
      path: '/financial/card/new',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (c, s) => const CreditCardFormScreen(),
    ),
    GoRoute(
      path: '/financial/card/edit/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (c, s) => CreditCardFormScreen(cardId: s.pathParameters['id']),
    ),
    GoRoute(
      path: '/capture',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (c, s) => const CaptureScreen(),
    ),
    GoRoute(
      path: '/search',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (c, s) => const SearchScreen(),
    ),
    GoRoute(path: '/auth/login', builder: (c, s) => const LoginScreen()),
    GoRoute(path: '/auth/register', builder: (c, s) => const RegisterScreen()),
    GoRoute(path: '/auth/forgot-password', builder: (c, s) => const ForgotPasswordScreen()),
    GoRoute(path: '/auth/reset-password', builder: (c, s) => const ResetPasswordScreen()),
  ],
);
