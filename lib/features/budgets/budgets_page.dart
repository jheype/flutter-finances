import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_financas/core/utils/format.dart';
import 'package:flutter_financas/data/models.dart';
import 'package:flutter_financas/data/repositories.dart';

/* ===================== Providers ===================== */

final _budgetRepoProvider = Provider((ref) => BudgetRepository());
final _catRepoProvider = Provider((ref) => CategoryRepository());
final _txRepoProvider = Provider((ref) => TransactionRepository());

final budgetsProvider =
    FutureProvider<List<BudgetModel>>((ref) => ref.watch(_budgetRepoProvider).getAll());

final monthSpendByCategoryProvider = FutureProvider<Map<int, int>>((ref) async {
  final txRepo = ref.watch(_txRepoProvider);
  final now = DateTime.now();
  final from = DateTime(now.year, now.month, 1);
  final to = DateTime(now.year, now.month + 1, 0).add(const Duration(days: 1));

  final txs = await txRepo.getAll(from: from, to: to);
  final Map<int, int> acc = {};
  for (final t in txs) {
    if (t.amountCents < 0) {
      acc[t.categoryId] = (acc[t.categoryId] ?? 0) + (-t.amountCents);
    }
  }
  return acc;
});

final categoriesProvider =
    FutureProvider<List<CategoryModel>>((ref) => ref.watch(_catRepoProvider).getAll());

/* ===================== Página ===================== */

class BudgetsPage extends ConsumerWidget {
  const BudgetsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetsProvider);
    final catsAsync = ref.watch(categoriesProvider);
    final spendsAsync = ref.watch(monthSpendByCategoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Budgets')),
      body: budgetsAsync.when(
        data: (budgets) {
          if (budgets.isEmpty) {
            return const _EmptyState('Nenhum budget ainda — toque em “Novo budget” para começar.');
          }
          return catsAsync.when(
            data: (cats) {
              final byId = {for (final c in cats) c.id!: c};
              return spendsAsync.when(
                data: (spends) {
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                    itemCount: budgets.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final b = budgets[i];
                      final cat = byId[b.categoryId];
                      final spent = spends[b.categoryId] ?? 0;
                      final limitCents = b.amountCents;
                      final progress = limitCents == 0 ? 0.0 : (spent / limitCents).clamp(0.0, 1.0);

                      return _BudgetCard(
                        category: cat,
                        spentCents: spent,
                        limitCents: limitCents,
                        progress: progress,
                        onEdit: () {
                          showDialog<BudgetModel>(
                            context: context,
                            builder: (_) => _BudgetForm(seed: b),
                          ).then((edited) async {
                            if (edited != null) {
                              await ref.read(_budgetRepoProvider).upsert(edited);
                              ref.invalidate(budgetsProvider);
                            }
                          });
                        },
                        onDelete: () {
                          showDialog<bool>(
                            context: context,
                            builder: (dialogCtx) => AlertDialog(
                              title: const Text('Excluir budget?'),
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
                          ).then((ok) async {
                            if (ok == true) {
                              await ref.read(_budgetRepoProvider).delete(b.id!);
                              ref.invalidate(budgetsProvider);
                            }
                          });
                        },
                      );
                    },
                  );
                },
                loading: () => const _SectionLoader(),
                error: (e, _) => Center(child: Text('Erro: $e')),
              );
            },
            loading: () => const _SectionLoader(),
            error: (e, _) => Center(child: Text('Erro: $e')),
          );
        },
        loading: () => const _SectionLoader(),
        error: (e, _) => Center(child: Text('Erro: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog<BudgetModel>(
            context: context,
            builder: (_) => const _BudgetForm(),
          ).then((model) async {
            if (model != null) {
              await ref.read(_budgetRepoProvider).upsert(model);
              ref.invalidate(budgetsProvider);
            }
          });
        },
        icon: const Icon(Icons.add),
        label: const Text('Novo budget'),
      ),
    );
  }
}

/* ===================== Cards / Widgets ===================== */

class _BudgetCard extends StatelessWidget {
  final CategoryModel? category;
  final int spentCents;
  final int limitCents;
  final double progress;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BudgetCard({
    required this.category,
    required this.spentCents,
    required this.limitCents,
    required this.progress,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final over = spentCents > limitCents && limitCents > 0;

    final title = category?.name ?? 'Categoria #${category?.id ?? '-'}';
    final color = category?.color ?? cs.primary;

    return Container(
      decoration:
          BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(18)),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          CircleAvatar(
              radius: 22,
              backgroundColor: color.withAlpha(70),
              child: const Icon(Icons.flag_rounded, color: Colors.white)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                    child: Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700))),
                _MoreMenu(onEdit: onEdit, onDelete: onDelete),
              ]),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 8,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(color: const Color(0xFF2A2A2D)),
                      FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress.isNaN ? 0 : progress,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient:
                                LinearGradient(colors: [cs.primary, cs.primary.withAlpha(140)]),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(children: [
                Text('Gasto',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall!
                        .copyWith(color: const Color(0xFF9E9E9E))),
                const SizedBox(width: 6),
                Text(Format.moneyFromCents(spentCents),
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: over ? const Color(0xFFF87171) : Colors.white)),
                const Spacer(),
                Text('Limite',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall!
                        .copyWith(color: const Color(0xFF9E9E9E))),
                const SizedBox(width: 6),
                Text(Format.moneyFromCents(limitCents),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ]),
            ]),
          ),
        ],
      ),
    );
  }
}

class _MoreMenu extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _MoreMenu({required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Mais ações',
      onSelected: (v) {
        if (v == 'edit') onEdit();
        if (v == 'delete') onDelete();
      },
      itemBuilder: (ctx) => const [
        PopupMenuItem(
            value: 'edit',
            child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Editar'))),
        PopupMenuItem(
            value: 'delete',
            child: ListTile(leading: Icon(Icons.delete_outline), title: Text('Excluir'))),
      ],
      child: const Icon(Icons.more_horiz, size: 22),
    );
  }
}

/* ===================== Formulário ===================== */

class _BudgetForm extends StatefulWidget {
  final BudgetModel? seed;
  const _BudgetForm({this.seed});

  @override
  State<_BudgetForm> createState() => _BudgetFormState();
}

class _BudgetFormState extends State<_BudgetForm> {
  final _formKey = GlobalKey<FormState>();
  final _value = TextEditingController();

  int? _categoryId;
  late DateTime _start;

  @override
  void initState() {
    super.initState();
    final seed = widget.seed;
    if (seed != null) {
      _categoryId = seed.categoryId;
      _value.text = (seed.amountCents / 100).toStringAsFixed(2).replaceAll('.', ',');
      _start = seed.start;
    } else {
      final now = DateTime.now();
      _start = DateTime(now.year, now.month, 1);
    }
  }

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesFuture = CategoryRepository().getAll();

    return AlertDialog(
      title: Text(widget.seed == null ? 'Novo budget' : 'Editar budget'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: FutureBuilder<List<CategoryModel>>(
            future: categoriesFuture,
            builder: (context, snap) {
              final items = snap.data ?? const <CategoryModel>[];

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(labelText: 'Categoria'),
                    items: [
                      for (final c in items)
                        DropdownMenuItem(
                          value: c.id,
                          child: Row(children: [
                            CircleAvatar(backgroundColor: c.color, radius: 6),
                            const SizedBox(width: 8),
                            Text(c.name),
                          ]),
                        ),
                    ],
                    initialValue: _categoryId,
                    onChanged: (v) => setState(() => _categoryId = v),
                    validator: (v) => v == null ? 'Selecione a categoria' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _value,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true, signed: false),
                    decoration:
                        const InputDecoration(labelText: 'Limite mensal', prefixText: 'R\$ '),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Informe um valor';
                      final cents = _parseToCents(v);
                      if (cents == null || cents <= 0) return 'Valor inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Período'),
                    subtitle: Text('Início: ${Format.date(_start)}'),
                    trailing: const Tooltip(
                        message: 'O período começa no 1º dia do mês atual',
                        child: Icon(Icons.info_outline)),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            final cents = _parseToCents(_value.text)!;

            final model = BudgetModel(
              id: widget.seed?.id,
              categoryId: _categoryId!,
              amountCents: cents,
              start: _start,
            );
            Navigator.pop(context, model);
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }

  int? _parseToCents(String input) {
    final cleaned = input
        .trim()
        .replaceAll('R\$', '')
        .replaceAll(' ', '')
        .replaceAll('.', '')
        .replaceAll(',', '.');
    final v = double.tryParse(cleaned);
    if (v == null) return null;
    return (v * 100).round();
  }
}

/* ===================== Utilitários visuais ===================== */

class _SectionLoader extends StatelessWidget {
  const _SectionLoader();
  @override
  Widget build(BuildContext context) {
    return const Center(
        child: Padding(padding: EdgeInsets.all(24.0), child: CircularProgressIndicator()));
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
