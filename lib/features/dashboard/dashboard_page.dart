import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_financas/core/utils/format.dart';
import 'package:flutter_financas/data/repositories.dart';

final _txRepoProvider = Provider((ref) => TransactionRepository());
final totalBalanceProvider =
    FutureProvider<int>((ref) => ref.watch(_txRepoProvider).totalBalanceCents());
final lastMonthsProvider = FutureProvider<List<Map<String, int>>>(
  (ref) => ref.watch(_txRepoProvider).lastMonthsNet(6),
);

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(totalBalanceProvider);
    final months = ref.watch(lastMonthsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Início')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Card: Saldo total
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Saldo total',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  balance.when(
                    data: (v) => Text(
                      Format.moneyFromCents(v),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    error: (e, _) => Text('Erro: $e'),
                    loading: () => const LinearProgressIndicator(minHeight: 2),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Card: Evolução (gráfico)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Evolução (últimos 6 meses)',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 220,
                    child: months.when(
                      data: (list) {
                        if (list.isEmpty) {
                          return const Center(
                            child: Text(
                              'Sem dados por enquanto — bora cadastrar as primeiras transações.',
                            ),
                          );
                        }

                        final spots = <FlSpot>[];
                        for (var i = 0; i < list.length; i++) {
                          final totalCents = list[i]['total']!;
                          spots.add(FlSpot(i.toDouble(), totalCents / 100.0));
                        }

                        return LineChart(
                          LineChartData(
                            gridData: const FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                            titlesData: FlTitlesData(
                              leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final idx = value.toInt();
                                    if (idx < 0 || idx >= list.length) {
                                      return const SizedBox.shrink();
                                    }
                                    final ym = list[idx]['yyyymm']!;
                                    final month = ym % 100; // pega MM de yyyymm
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        month.toString().padLeft(2, '0'),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            lineBarsData: [
                              LineChartBarData(
                                isCurved: true,
                                barWidth: 3,
                                dotData: const FlDotData(show: false),
                                spots: spots,
                              ),
                            ],
                          ),
                        );
                      },
                      error: (e, _) => Text('Erro: $e'),
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
