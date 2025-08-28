import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_financas/core/utils/format.dart';
import 'package:flutter_financas/data/models.dart';
import 'package:flutter_financas/data/repositories.dart';
import 'package:flutter_financas/data/providers.dart'; // <— provedor único

final _txRepoProvider = Provider((ref) => TransactionRepository());

/// Saldo total
final balanceProvider =
    FutureProvider<int>((ref) => ref.watch(_txRepoProvider).totalBalanceCents());

/// “Recentes”: busca TUDO (receitas e despesas), sem filtro
final recentTxProvider = FutureProvider<List<TransactionModel>>(
  (ref) => ref.watch(_txRepoProvider).getRecent(limit: 8),
);

/// Analytics agregado em DART (mais robusto entre plataformas)
final analyticsProvider = FutureProvider<List<Map<String, num>>>((ref) async {
  final repo = ref.watch(_txRepoProvider);
  const monthsBack = 6;
  final now = DateTime.now();
  final start = DateTime(now.year, now.month - (monthsBack - 1), 1);
  final end = DateTime(now.year, now.month + 1, 1);

  final txs = await repo.getAll(from: start, to: end);

  // cria lista de meses vazios
  final months = <DateTime>[];
  for (int i = 0; i < monthsBack; i++) {
    months.add(DateTime(start.year, start.month + i, 1));
  }

  // agrega por mês (saldo líquido)
  final totals = {for (final m in months) _ymKey(m): 0};
  for (final t in txs) {
    final k = _ymKey(DateTime(t.date.year, t.date.month, 1));
    if (totals.containsKey(k)) {
      totals[k] = (totals[k] ?? 0) + t.amountCents;
    }
  }

  // retorno ordenado
  return months
      .map((m) => {
            'yyyymm': m.year * 100 + m.month,
            'total': totals[_ymKey(m)] ?? 0,
          })
      .toList();
});

String _ymKey(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(balanceProvider);
    final recent = ref.watch(recentTxProvider);
    final cats = ref.watch(categoriesAllProvider); // <— único
    final analytics = ref.watch(analyticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.go('/settings'),
            tooltip: 'Configurações',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _BalanceCard(balance: balance)),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _SectionHeader(
              title: 'Analytics',
              action: TextButton(
                  onPressed: () => context.go('/transactions'), child: const Text('Ver tudo')),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _AnalyticsCard(analytics: analytics),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _SectionHeader(
              title: 'Transações recentes',
              action: TextButton(
                  onPressed: () => context.go('/transactions'), child: const Text('Abrir lista')),
            ),
          ),
          const SizedBox(height: 8),
          recent.when(
            data: (txs) {
              if (txs.isEmpty)
                return const _EmptyState(message: 'Sem transações ainda — adicione a primeira!');
              return cats.when(
                data: (list) {
                  final byId = {for (final c in list) c.id!: c};
                  return Column(
                    children: [
                      for (final t in txs) _RecentTxTile(tx: t, category: byId[t.categoryId])
                    ],
                  );
                },
                loading: () => const _SectionLoader(height: 160),
                error: (e, _) => _ErrorState('$e'),
              );
            },
            loading: () => const _SectionLoader(height: 160),
            error: (e, _) => _ErrorState('$e'),
          ),
        ],
      ),
    );
  }
}

/* ---- COMPONENTES ---- */

class _BalanceCard extends StatelessWidget {
  final AsyncValue<int> balance;
  const _BalanceCard({required this.balance});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF1E1E1E), const Color(0xFF1C1C1E), cs.primary.withAlpha(24)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: balance.when(
          data: (cents) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Saldo disponível',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall!
                      .copyWith(color: const Color(0xFF9E9E9E))),
              const SizedBox(height: 6),
              Text(Format.moneyFromCents(cents),
                  style: Theme.of(context)
                      .textTheme
                      .displaySmall!
                      .copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              Row(
                children: [
                  _pillButton(context,
                      icon: Icons.add,
                      label: 'Nova transação',
                      onTap: () => context.go('/transactions')),
                  const SizedBox(width: 10),
                  _pillOutline(context,
                      icon: Icons.flag, label: 'Budgets', onTap: () => context.go('/budgets')),
                ],
              ),
            ],
          ),
          loading: () => const _Skeleton(height: 64),
          error: (e, _) => _ErrorState('$e'),
        ),
      ),
    );
  }

  Widget _pillButton(BuildContext context,
      {required IconData icon, required String label, required VoidCallback onTap}) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white))
        ]),
      ),
    );
  }

  Widget _pillOutline(BuildContext context,
      {required IconData icon, required String label, required VoidCallback onTap}) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
            border: Border.all(color: cs.primary.withAlpha(80)),
            borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 8),
          Text(label)
        ]),
      ),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  final AsyncValue<List<Map<String, num>>> analytics;
  const _AnalyticsCard({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      decoration:
          BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
      height: 190,
      child: analytics.when(
        data: (list) {
          if (list.isEmpty) return const Center(child: Text('Sem dados ainda'));
          final spots = <FlSpot>[];
          num maxAbs = 0;
          for (var i = 0; i < list.length; i++) {
            final cents = list[i]['total'] ?? 0;
            maxAbs = cents.abs() > maxAbs ? cents.abs() : maxAbs;
            spots.add(FlSpot(i.toDouble(), (cents.toDouble()) / 100.0));
          }
          if (maxAbs == 0) maxAbs = 100; // evita eixo colapsado
          final maxY = (maxAbs / 100.0) * 1.2;

          return LineChart(
            LineChartData(
              minY: -maxY,
              maxY: maxY,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= list.length) return const SizedBox.shrink();
                      final ym = (list[idx]['yyyymm'] ?? 0).toInt();
                      final m = ym % 100;
                      return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(m.toString().padLeft(2, '0')));
                    },
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  isCurved: true,
                  preventCurveOverShooting: true,
                  barWidth: 3,
                  dotData: const FlDotData(show: false),
                  color: primary,
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [primary.withAlpha(120), primary.withAlpha(15)],
                    ),
                  ),
                  spots: spots,
                ),
              ],
            ),
          );
        },
        loading: () => const _Skeleton(height: 140),
        error: (e, _) => _ErrorState('$e'),
      ),
    );
  }
}

class _RecentTxTile extends StatelessWidget {
  final TransactionModel tx;
  final CategoryModel? category;
  const _RecentTxTile({required this.tx, required this.category});

  @override
  Widget build(BuildContext context) {
    final amountColor = tx.amountCents > 0 ? const Color(0xFF4ADE80) : const Color(0xFFF87171);
    final icon = category?.icon ?? Icons.category_rounded;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => context.go('/transactions'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration:
            BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(18)),
        child: Row(
          children: [
            CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF2A2A2D),
                child: Icon(icon, color: Colors.white, size: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(category?.name ?? 'Categoria #${tx.categoryId}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(Format.date(tx.date),
                    style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 12)),
              ]),
            ),
            const SizedBox(width: 8),
            Text(Format.moneyFromCents(tx.amountCents),
                style: TextStyle(color: amountColor, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

/* ---- utilitários visuais ---- */

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;
  const _SectionHeader({required this.title, this.action});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(title,
          style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w700)),
      const Spacer(),
      if (action != null) action!,
    ]);
  }
}

class _Skeleton extends StatelessWidget {
  final double height;
  const _Skeleton({required this.height});
  @override
  Widget build(BuildContext context) => Container(
      height: height,
      decoration:
          BoxDecoration(color: const Color(0xFF26262A), borderRadius: BorderRadius.circular(16)));
}

class _SectionLoader extends StatelessWidget {
  final double height;
  const _SectionLoader({required this.height});
  @override
  Widget build(BuildContext context) =>
      SizedBox(height: height, child: const Center(child: CircularProgressIndicator()));
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Center(
            child: Text(message,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium!
                    .copyWith(color: const Color(0xFF9E9E9E)))),
      );
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState(this.message);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child:
            Center(child: Text('Erro: $message', style: const TextStyle(color: Colors.redAccent))),
      );
}
