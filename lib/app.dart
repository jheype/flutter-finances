import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_financas/core/theme.dart';
import 'package:flutter_financas/features/dashboard/dashboard_page.dart';
import 'package:flutter_financas/features/categories/categories_page.dart';
import 'package:flutter_financas/features/transactions/transactions_page.dart';
import 'package:flutter_financas/features/budgets/budgets_page.dart';
import 'package:flutter_financas/features/settings/settings_page.dart';
import 'package:flutter_financas/widgets/adaptive_scaffold.dart';

class FinancasApp extends StatelessWidget {
  const FinancasApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTextTheme = GoogleFonts.interTextTheme();

    return MaterialApp.router(
      title: 'Finanças',
      debugShowCheckedModeBanner: false,

      // pt-BR por padrão
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],

      themeMode: ThemeMode.dark,
      theme: AppTheme.light(baseTextTheme),
      darkTheme: AppTheme.dark(baseTextTheme),

      routerConfig: _router,
    );
  }
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => AdaptiveScaffold(child: child),
      routes: [
        GoRoute(
          path: '/',
          name: 'dashboard',
          builder: (context, state) => const DashboardPage(),
        ),
        GoRoute(
          path: '/transactions',
          name: 'transactions',
          builder: (context, state) => const TransactionsPage(),
        ),
        GoRoute(
          path: '/categories',
          name: 'categories',
          builder: (context, state) => const CategoriesPage(),
        ),
        GoRoute(
          path: '/budgets',
          name: 'budgets',
          builder: (context, state) => const BudgetsPage(),
        ),
        GoRoute(
          path: '/settings',
          name: 'settings',
          builder: (context, state) => const SettingsPage(),
        ),
      ],
    ),
  ],
);
