import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_financas/core/utils/format.dart';
import 'package:flutter_financas/data/models.dart';
import 'package:flutter_financas/data/repositories.dart';
import 'package:flutter_financas/data/providers.dart'; // <— provedor único
import 'package:flutter_financas/features/transactions/transaction_form.dart';

/* ===================== Providers ===================== */

final _txRepoProvider = Provider((ref) => TransactionRepository());

enum TxFilter { all, income, expense }

final txFilterProvider = StateProvider<TxFilter>((_) => TxFilter.all);
final txRangeProvider = StateProvider<DateTimeRange?>((_) => null);

final transactionsProvider = FutureProvider<List<TransactionModel>>((ref) async {
  final repo = ref.watch(_txRepoProvider);
  final filter = ref.watch(txFilterProvider);
  final range = ref.watch(txRangeProvider);

  DateTime? from;
  DateTime? to;
  if (range != null) {
    from = DateTime(range.start.year, range.start.month, range.start.day);
    to = DateTime(range.end.year, range.end.month, range.end.day + 1);
  }

  final all = await repo.getAll(from: from, to: to);
  switch (filter) {
    case TxFilter.income:
      return all.where((t) => t.amountCents > 0).toList();
    case TxFilter.expense:
      return all.where((t) => t.amountCents < 0).toList();
    case TxFilter.all:
      return all;
  }
});

final periodTotalProvider = FutureProvider<int>((ref) async {
  final list = await ref.watch(transactionsProvider.future);
  return list.fold<int>(0, (sum, t) => sum + t.amountCents);
});

/* ===================== Página ===================== */

class TransactionsPage extends ConsumerWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txsAsync = ref.watch(transactionsProvider);
    final catsAsync = ref.watch(categoriesAllProvider); // <— único
    final totalAsync = ref.watch(periodTotalProvider);
    final range = ref.watch(txRangeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Transações')),
      body: Column(
        children: [
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _Header(
              total: totalAsync,
              onNew: () {
                showDialog<TransactionModel>(
                  context: context,
                  builder: (_) => const TransactionForm(),
                ).then((model) async {
                  if (model != null) {
                    await ref.read(_txRepoProvider).insert(model);
                    ref.invalidate(transactionsProvider);
                  }
                });
              },
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _FiltersRow(
              range: range,
              onPickRange: () async {
                final now = DateTime.now();
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(now.year - 3),
                  lastDate: DateTime(now.year + 3),
                  initialDateRange: range ??
                      DateTimeRange(
                        start: DateTime(now.year, now.month, 1),
                        end: DateTime(now.year, now.month + 1, 0),
                      ),
                  locale: const Locale('pt', 'BR'),
                );
                if (picked != null) {
                  ref.read(txRangeProvider.notifier).state = picked;
                }
              },
              onClearRange: () => ref.read(txRangeProvider.notifier).state = null,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: txsAsync.when(
              data: (list) {
                if (list.isEmpty) {
                  return const _EmptyState('Nada por aqui… adicione sua primeira transação ✨');
                }
                return catsAsync.when(
                  data: (cats) {
                    final byId = {for (final c in cats) c.id!: c};
                    return ListView.separated(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (context, i) {
                        final t = list[i];
                        final cat = byId[t.categoryId];
                        return Dismissible(
                          key: ValueKey('tx_${t.id}_$i'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withAlpha(120),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: const Icon(Icons.delete_outline),
                          ),
                          confirmDismiss: (_) {
                            return showDialog<bool>(
                              context: context,
                              builder: (dialogCtx) => AlertDialog(
                                title: const Text('Excluir transação?'),
                                content: const Text('Essa ação não pode ser desfeita.'),
                                actions: [
                                  TextButton(
                                      onPressed: () => Navigator.pop(dialogCtx, false),
                                      child: const Text('Cancelar')),
                                  FilledButton.tonal(
                                      onPressed: () => Navigator.pop(dialogCtx, true),
                                      child: const Text('Excluir')),
                                ],
                              ),
                            ).then((ok) => ok ?? false);
                          },
                          onDismissed: (_) async {
                            await ref.read(_txRepoProvider).delete(t.id!);
                            ref.invalidate(transactionsProvider);
                          },
                          child: _TransactionTile(tx: t, category: cat),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Erro: $e')),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erro: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog<TransactionModel>(
            context: context,
            builder: (_) => const TransactionForm(),
          ).then((model) async {
            if (model != null) {
              await ref.read(_txRepoProvider).insert(model);
              ref.invalidate(transactionsProvider);
            }
          });
        },
        icon: const Icon(Icons.add),
        label: const Text('Nova transação'),
      ),
    );
  }
}

/* ===== componentes auxiliares (iguais aos que você já tinha) ===== */

class _Header extends StatelessWidget {
  final AsyncValue<int> total;
  final VoidCallback onNew;
  const _Header({required this.total, required this.onNew});

  @override
  Widget build(BuildContext context) {
    final txt = Theme.of(context).textTheme;

    return Container(
      decoration:
          BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(18)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: total.when(
              data: (cents) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total no período',
                      style: txt.bodySmall!.copyWith(color: const Color(0xFF9E9E9E))),
                  const SizedBox(height: 4),
                  Text(Format.moneyFromCents(cents),
                      style: txt.titleLarge!.copyWith(fontWeight: FontWeight.w800)),
                ],
              ),
              loading: () => const _ShimmerBox(width: 120, height: 20),
              error: (e, _) => Text('Erro: $e'),
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
              onPressed: onNew, icon: const Icon(Icons.add), label: const Text('Nova')),
        ],
      ),
    );
  }
}

class _FiltersRow extends ConsumerWidget {
  final VoidCallback onPickRange;
  final VoidCallback onClearRange;
  final DateTimeRange? range;

  const _FiltersRow({required this.onPickRange, required this.onClearRange, required this.range});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(txFilterProvider);

    Widget chip(String label, TxFilter v, IconData icon) {
      final isSel = selected == v;
      return ChoiceChip(
        label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [Icon(icon, size: 16), const SizedBox(width: 6), Text(label)]),
        visualDensity: VisualDensity.compact,
        selected: isSel,
        onSelected: (_) => ref.read(txFilterProvider.notifier).state = v,
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        chip('Todas', TxFilter.all, Icons.all_inclusive),
        chip('Receitas', TxFilter.income, Icons.trending_up),
        chip('Despesas', TxFilter.expense, Icons.trending_down),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: onPickRange,
          icon: const Icon(Icons.calendar_today_outlined, size: 18),
          label: Text(
            range == null
                ? 'Período'
                : '${Format.compactDate(range!.start)} – ${Format.compactDate(range!.end)}',
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          tooltip: 'Limpar período',
          onPressed: range == null ? null : onClearRange,
          icon: const Icon(Icons.filter_alt_off_outlined),
        ),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final TransactionModel tx;
  final CategoryModel? category;
  const _TransactionTile({required this.tx, required this.category});

  @override
  Widget build(BuildContext context) {
    final isIncome = tx.amountCents > 0;
    final amountColor = isIncome ? const Color(0xFF4ADE80) : const Color(0xFFF87171);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration:
          BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFF2A2A2D),
            child: Icon(category?.icon ?? Icons.category_rounded, color: Colors.white, size: 20),
          ),
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
          SizedBox(
            width: 110,
            child: Text(
              Format.moneyFromCents(tx.amountCents),
              textAlign: TextAlign.end,
              style: TextStyle(color: amountColor, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String msg;
  const _EmptyState(this.msg);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Text(msg,
            textAlign: TextAlign.center,
            style:
                Theme.of(context).textTheme.bodyMedium!.copyWith(color: const Color(0xFF9E9E9E))),
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  const _ShimmerBox({required this.width, required this.height});
  @override
  Widget build(BuildContext context) {
    return Container(
        width: width,
        height: height,
        decoration:
            BoxDecoration(color: const Color(0xFF2A2A2D), borderRadius: BorderRadius.circular(8)));
  }
}
